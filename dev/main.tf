# --- Default VPC + default subnets ---
resource "aws_default_vpc" "default" {
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-vpc"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "default_vpc" {
  depends_on = [aws_default_vpc.default]

  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

locals {
  default_subnet_ids = sort(data.aws_subnets.default_vpc.ids)

  instance_keys_sorted = sort(keys(var.instances))

  instance_index = {
    for idx, k in local.instance_keys_sorted : k => idx
  }

  keypair_name_by_instance = {
    for k in keys(var.instances) : k => "${var.keypair_name_prefix}${k}"
  }

  pem_path_by_instance = {
    for k in keys(var.instances) : k => "${var.ssh_private_key_dir}/${local.keypair_name_by_instance[k]}.pem"
  }
}

# --- Ubuntu AMI (22.04 LTS) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- SSH key: generate locally, upload public key to AWS ----
resource "tls_private_key" "ssh" {
  for_each  = var.instances
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "per_instance" {
  for_each = var.instances

  key_name   = local.keypair_name_by_instance[each.key]
  public_key = tls_private_key.ssh[each.key].public_key_openssh

  tags = merge(var.tags, try(each.value.tags, {}), {
    Name = local.keypair_name_by_instance[each.key]
  })
}

resource "local_file" "private_key_pem" {
  for_each = var.instances

  filename        = local.pem_path_by_instance[each.key]
  content         = tls_private_key.ssh[each.key].private_key_pem
  file_permission = "0600"
}

# --- Security group: allow SSH ---
resource "aws_security_group" "ssh" {
  name_prefix = "${var.name_prefix}-ssh-"
  description = "Allow SSH inbound"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for testing"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for testing"
  }

  # Development ports (3000, 8080, 8000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Development server port 3000"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Development server port 8080"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Development server port 8000"
  }

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Development server port 8888"
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssh"
  })
}

# --- EC2 instances ---
resource "aws_instance" "this" {
  for_each = var.instances

  ami           = data.aws_ami.ubuntu.id
  instance_type = each.value.instance_type

  subnet_id = coalesce(
    try(each.value.subnet_id, null),
    local.default_subnet_ids[local.instance_index[each.key] % length(local.default_subnet_ids)]
  )

  associate_public_ip_address = each.value.associate_public_ip

  key_name = aws_key_pair.per_instance[each.key].key_name

  vpc_security_group_ids = concat(
    [aws_security_group.ssh.id],
    each.value.extra_security_group_ids
  )

  root_block_device {
    volume_size = each.value.root_volume_gb
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data_base64 = data.cloudinit_config.devtools.rendered

  tags = merge(var.tags, each.value.tags, {
    Name          = "${var.name_prefix}-${each.key}"
    AutoStop      = tostring(each.value.enable_autostop)
    AutoStopGroup = var.autostop_group_name
  })

  lifecycle {
    ignore_changes = all
  }
}

# --- Nightly stop schedule (19:00 WIB = 12:00 UTC) ---
data "aws_iam_policy_document" "eventbridge_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_ssm_automation" {
  name               = "${var.name_prefix}-eventbridge-ssm-automation"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "eventbridge_start_automation" {
  name = "${var.name_prefix}-eventbridge-start-automation"
  role = aws_iam_role.eventbridge_ssm_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:StartAutomationExecution"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "automation_stop_instances" {
  name = "${var.name_prefix}-automation-stop-instances"
  role = aws_iam_role.eventbridge_ssm_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "nightly_stop" {
  name                = "${var.name_prefix}-nightly-stop"
  description         = "Stop EC2 instances nightly at 19:00 WIB (12:00 UTC)"
  schedule_expression = var.autostop_schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "nightly_stop_ssm" {
  rule     = aws_cloudwatch_event_rule.nightly_stop.name
  arn      = "arn:aws:ssm:${var.aws_region}::automation-definition/AWS-StopEC2Instance:$DEFAULT"
  role_arn = aws_iam_role.eventbridge_ssm_automation.arn

  input = jsonencode({
    InstanceId = [
      for k, inst in aws_instance.this :
      inst.id if try(var.instances[k].enable_autostop, true)
    ]
  })
}

# --- Cloud Init ---
data "cloudinit_config" "devtools" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<-YAML
      #cloud-config
      package_update: true
      package_upgrade: true

      packages:
        - ca-certificates
        - curl
        - unzip
        - git
        - jq
        - gnupg
        - lsb-release
        - make
        - gcc
        - g++
        - build-essential
        - python3
        - python3-pip
        - python3-venv
        - software-properties-common
        - apt-transport-https
        - htop
        - tmux
        - ripgrep
        - fzf
        - tar
        - gzip
        - openssh-client

      runcmd:
        # ---- Wait - Prevents intermittent failures ----
        - [ bash, -lc, "set -euo pipefail; for i in $(seq 1 60); do if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then echo \"apt lock present, waiting... ($i)\"; sleep 2; else break; fi; done" ]

        # ---- AWS CLI v2 ----
        - [ bash, -lc, "set -euo pipefail; cd /tmp && curl -sSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ]
        - [ bash, -lc, "set -euo pipefail; cd /tmp && unzip -q awscliv2.zip" ]
        - [ bash, -lc, "set -euo pipefail; /tmp/aws/install --update" ]
        - [ bash, -lc, "aws --version" ]

        # ---- Docker Engine + compose plugin ----
        - [ bash, -lc, "set -euo pipefail; install -m 0755 -d /etc/apt/keyrings" ]
        - [ bash, -lc, "set -euo pipefail; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg" ]
        - [ bash, -lc, "set -euo pipefail; chmod a+r /etc/apt/keyrings/docker.gpg" ]
        - [ bash, -lc, "set -euo pipefail; echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable\" > /etc/apt/sources.list.d/docker.list" ]
        - [ bash, -lc, "set -euo pipefail; apt-get update -y" ]
        - [ bash, -lc, "set -euo pipefail; apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" ]
        - [ bash, -lc, "systemctl enable --now docker" ]
        - [ bash, -lc, "usermod -aG docker ubuntu" ]
        - [ bash, -lc, "docker --version" ]
        - [ bash, -lc, "docker compose version" ]

        # ---- GitHub CLI (gh) ----
        - [ bash, -lc, "set -euo pipefail; install -m 0755 -d /etc/apt/keyrings" ]
        - [ bash, -lc, "set -euo pipefail; curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg" ]
        - [ bash, -lc, "set -euo pipefail; chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg" ]
        - [ bash, -lc, "set -euo pipefail; echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" > /etc/apt/sources.list.d/github-cli.list" ]
        - [ bash, -lc, "set -euo pipefail; apt-get update -y && apt-get install -y gh" ]
        - [ bash, -lc, "gh --version" ]

         # ---- Starship prompt ----
        - [ bash, -lc, "set -euo pipefail; curl -fsSL https://starship.rs/install.sh | sh -s -- -y" ]
        - [ bash, -lc, "set -euo pipefail; sudo -u ubuntu -H bash -lc 'mkdir -p ~/.config && starship preset no-empty-icons -o ~/.config/starship.toml'" ]
        - [ bash, -lc, "set -euo pipefail; grep -qxF 'eval \"$(starship init bash)\"' /home/ubuntu/.bashrc || echo 'eval \"$(starship init bash)\"' >> /home/ubuntu/.bashrc" ]
        - [ bash, -lc, "set -euo pipefail; chown ubuntu:ubuntu /home/ubuntu/.bashrc" ]

        # ---- uv ----
        - [ bash, -lc, "set -euo pipefail; sudo -u ubuntu -H bash -lc 'curl -fsSL https://astral.sh/uv/install.sh | sh'" ]
        - [ bash, -lc, "set -euo pipefail; grep -qxF 'export PATH=\"$HOME/.local/bin:$PATH\"' /home/ubuntu/.bashrc || echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> /home/ubuntu/.bashrc" ]
        - [ bash, -lc, "set -euo pipefail; sudo -u ubuntu -H bash -lc '$HOME/.local/bin/uv --version'" ]
        - [ bash, -lc, "set -euo pipefail; chown ubuntu:ubuntu /home/ubuntu/.bashrc" ]

         # ---- SSH keepalive: allow idle sessions to survive ~12h ----
        - [ bash, -lc, "set -euo pipefail; grep -q '^ClientAliveInterval' /etc/ssh/sshd_config && sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config || echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config" ]
        - [ bash, -lc, "set -euo pipefail; grep -q '^ClientAliveCountMax' /etc/ssh/sshd_config && sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 144/' /etc/ssh/sshd_config || echo 'ClientAliveCountMax 144' >> /etc/ssh/sshd_config" ]
        - [ bash, -lc, "set -euo pipefail; systemctl restart ssh" ]

        # ---- defaults ----
        - [ bash, -lc, "grep -qxF 'export EDITOR=vim' /home/ubuntu/.bashrc || echo 'export EDITOR=vim' >> /home/ubuntu/.bashrc" ]
        - [ bash, -lc, "chown ubuntu:ubuntu /home/ubuntu/.bashrc" ]
    YAML
  }
}
