# --- IRSA ---
module "efs_csi_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.55.0"
  role_name             = "${local.cluster}-efs-csi"
  attach_efs_csi_policy = true

  role_policy_arns = {
    EFSClientWrite = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

# --- Security group for EFS ---
resource "aws_security_group" "efs" {
  name_prefix = "${local.cluster}-efs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "NFS traffic from EKS cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.cluster}-efs-sg"
  })
}

# --- EFS File System ---
resource "aws_efs_file_system" "data" {
  creation_token   = "${local.cluster}-efs"
  performance_mode = "generalPurpose" # or "maxIO" for high throughput

  throughput_mode = "bursting" # or "elastic"/"provisioned"
  # provisioned_throughput_in_mibps = 100 # Uncomment and set if using "provisioned"

  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(local.tags, {
    Name = "${local.cluster}-efs"
  })
}

# --- EFS Mount Targets ---
resource "aws_efs_mount_target" "data" {
  count           = length(var.private_subnets_ids)
  file_system_id  = aws_efs_file_system.data.id
  subnet_id       = var.private_subnets_ids[count.index]
  security_groups = [aws_security_group.efs.id]


  depends_on = [aws_efs_file_system.data, aws_security_group.efs]
}

# --- Enable EFS Backup ---
resource "aws_efs_backup_policy" "data" {
  file_system_id = aws_efs_file_system.data.id

  backup_policy {
    status = var.efs_backup_enabled ? "ENABLED" : "DISABLED"
  }
}

# --- EFS Lifecycle Policy ---
resource "aws_efs_file_system_policy" "data" {
  file_system_id = aws_efs_file_system.data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}
