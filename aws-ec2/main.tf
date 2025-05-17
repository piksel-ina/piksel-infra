# --- Data source to fetch the latest Ubuntu AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Generate a new SSH key pair using TLS provider ---
resource "tls_private_key" "test_keypair" {
  count     = (var.create_test_ec2 || var.create_dev_ec2) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  count           = (var.create_test_ec2 || var.create_dev_ec2) ? 1 : 0
  content         = tls_private_key.test_keypair[0].private_key_pem
  filename        = "${var.local_key_path}/${var.key_name}.pem"
  file_permission = "0600"
}

# --- Save the public key to a local file ---
resource "local_file" "public_key" {
  count           = (var.create_test_ec2 || var.create_dev_ec2) ? 1 : 0
  content         = tls_private_key.test_keypair[0].public_key_openssh
  filename        = "${var.local_key_path}/${var.key_name}.pub"
  file_permission = "0644"
}

# --- Create the key pair in AWS using the generated public key ---
resource "aws_key_pair" "test_keypair" {
  count      = (var.create_test_ec2 || var.create_dev_ec2) ? 1 : 0
  key_name   = var.key_name
  public_key = tls_private_key.test_keypair[0].public_key_openssh

  tags = {
    Name = "test-ec2-keypair"
  }
}

# --- Security Group to allow SSH access ---
resource "aws_security_group" "ec2_sg" {
  count       = (var.create_test_ec2 || var.create_dev_ec2) ? 1 : 0
  name        = "ec2-sg"
  description = "Security Group for EC2 instances with SSH access"
  vpc_id      = var.vpc_id

  # Allow SSH inbound
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# --- Create Testing EC2 instance ---
resource "aws_instance" "test_ec2" {
  count                  = var.create_test_ec2 ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.test_instance_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.test_keypair[0].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg[0].id]

  user_data = <<-EOF
              #!/bin/bash
              echo "nameserver 169.254.169.253" > /etc/resolv.conf
              apt-get update
              apt-get install -y dnsutils
              EOF

  tags = {
    Name = "test-ec2-instance"
  }
}

# --- Create Personal Dev EC2 instance ---
resource "aws_instance" "dev_ec2" {
  count                  = var.create_dev_ec2 ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.dev_instance_type
  subnet_id              = var.subnet_id
  key_name               = aws_key_pair.test_keypair[0].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg[0].id]

  root_block_device {
    volume_size = var.dev_volume_size
    volume_type = "gp3"
  }

  # --- basic setup ---
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y dnsutils git curl  # Basic tools for development
              EOF

  tags = {
    Name = "personal-dev-ec2"
  }
}
