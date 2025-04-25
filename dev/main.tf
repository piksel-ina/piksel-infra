data "aws_availability_zones" "available" {}

locals {
  name     = "${var.project}-${var.environment}"
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = merge(var.common_tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = local.name
  cidr = local.vpc_cidr
  azs  = local.azs

  # Subnet CIDR blocks
  public_subnets   = ["10.0.0.0/24", "10.0.3.0/24"] # Public subnets for NAT Gateway, ALB
  private_subnets  = ["10.0.1.0/24", "10.0.4.0/24"] # Private app subnets for EKS nodes
  database_subnets = ["10.0.2.0/24", "10.0.5.0/24"] # Private data subnets for RDS, ElastiCache

  # Subnet naming
  public_subnet_names   = ["Public Subnet A", "Public Subnet B"]
  private_subnet_names  = ["Private App Subnet A", "Private App Subnet B"]
  database_subnet_names = ["Private Data Subnet A", "Private Data Subnet B"]

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "prod" # Use single NAT for non-prod environments
  one_nat_gateway_per_az = var.environment == "prod" # One NAT per AZ for prod as per network.md

  # VPC Flow Logs configuration
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

  # Essential EKS tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.name}-cluster" = "shared"
  }

  tags = local.tags
}

################################################################################
# VPC Endpoints
################################################################################
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      tags            = { Name = "${local.name}-s3-endpoint" }
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.name}-ecr-api-endpoint" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.name}-ecr-dkr-endpoint" }
    }
  }

  tags = local.tags
}

################################################################################
# EKS Cluster Security Group
################################################################################
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_inbound" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow worker nodes to communicate with the cluster API Server"
}

resource "aws_security_group_rule" "cluster_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow all outbound traffic"
}

################################################################################
# EKS Node Group Security Group
################################################################################
resource "aws_security_group" "node_group" {
  name        = "${local.name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name                                          = "${local.name}-node-sg"
    "kubernetes.io/cluster/${local.name}-cluster" = "owned"
  })
}

resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

resource "aws_security_group_rule" "nodes_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node_group.id
  description       = "Allow all outbound traffic"
}

################################################################################
# ALB Security Group
################################################################################
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP inbound traffic"
}

resource "aws_security_group_rule" "alb_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS inbound traffic"
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

################################################################################
# Database Security Group
################################################################################
resource "aws_security_group" "database" {
  name        = "${local.name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-db-sg"
  })
}

resource "aws_security_group_rule" "database_inbound" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.database.id
  description              = "Allow PostgreSQL access from EKS nodes"
}


################################################################################
# KMS Key for S3 Encryption
################################################################################

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption in ${local.name}"
  deletion_window_in_days = var.s3_kms_key_deletion_window_in_days
  enable_key_rotation     = true
  tags                    = merge(local.tags, { Name = "${local.name}-s3-kms-key" })

  # Default policy allows root user full control and enables IAM policy usage
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
      # Add statements here later if specific services need direct KMS access
    ]
  })
}

resource "aws_kms_alias" "s3_key" {
  name          = "alias/${local.name}-s3"
  target_key_id = aws_kms_key.s3_key.key_id
}

data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "s3_log_bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.name}-logs/*" # Grant access only to the specific bucket ARN
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::${local.name}-*"] # Allow logs from buckets matching the pattern
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}


################################################################################
# S3 Access Logging Bucket
################################################################################

module "s3_log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0" # Pinning to the requested version

  bucket = "${local.name}-logs" # e.g., piksel-dev-logs

  # Use default SSE-S3 encryption for simplicity on the log bucket itself
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Attach policy to allow S3 logging service to write
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_log_bucket_policy.json

  # Lifecycle rule to expire logs
  lifecycle_rule = [
    {
      id      = "log-expiration"
      enabled = true
      filter = {
        prefix = "" # Empty prefix means apply to all objects
      }
      expiration = {
        days = var.s3_log_retention_days
      }
    }
  ]

  # Enable versioning for log bucket recommended practice
  versioning = {
    enabled = true
  }

  # Allow force destroy only in non-prod
  force_destroy = var.s3_log_bucket_force_destroy

  tags = merge(local.tags, {
    Purpose = "s3-access-logs"
    Name    = "${local.name}-logs"
  })
}

################################################################################
# S3 Bucket Policies (TLS and VPC Endpoint Enforcement)
################################################################################

data "aws_iam_policy_document" "s3_tls_vpce_enforcement" {
  # Policy for buckets requiring both TLS and VPC Endpoint access
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.name}-data/*",      # Apply to objects within the data bucket
      "arn:aws:s3:::${local.name}-data",        # Apply to the bucket itself
      "arn:aws:s3:::${local.name}-notebooks/*", # Apply to objects within the notebooks bucket
      "arn:aws:s3:::${local.name}-notebooks",   # Apply to the bucket itself
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyAccessOutsideVPCE"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.name}-data/*",
      "arn:aws:s3:::${local.name}-data",
      "arn:aws:s3:::${local.name}-notebooks/*",
      "arn:aws:s3:::${local.name}-notebooks",
    ]
    condition {
      test     = "StringNotEqualsIfExists" # Use IfExists because global services might not have VPC context
      variable = "aws:sourceVpce"
      values   = [module.vpc_endpoints.endpoints["s3"].id] # Reference the created S3 VPC Endpoint ID
    }
    # Add exceptions here if needed (e.g., specific roles/users needing console access)
    # condition {
    #   test = "ArnNotLike"
    #   variable = "aws:PrincipalArn"
    #   values = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/YourAdminRole"]
    # }
  }
}

data "aws_iam_policy_document" "s3_tls_only_enforcement" {
  # Policy for buckets requiring only TLS (like the dev web bucket)
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.name}-web/*", # Apply to objects within the web bucket
      "arn:aws:s3:::${local.name}-web",   # Apply to the bucket itself
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

################################################################################
# Piksel Data Bucket (Dev)
################################################################################

module "s3_bucket_data_dev" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"

  bucket = "${local.name}-data" # e.g., piksel-dev-data

  # Encryption using the dedicated KMS key
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.arn
      }
      bucket_key_enabled = true # Enable S3 Bucket Key for cost savings
    }
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable versioning
  versioning = {
    enabled = true
  }

  # Configure access logging
  logging = {
    target_bucket = module.s3_log_bucket.s3_bucket_id
    target_prefix = "s3/${local.name}-data/"
  }

  # Lifecycle rules (Transition raw data)
  lifecycle_rule = [
    {
      id      = "raw-transition-to-ia"
      enabled = true
      filter = {
        prefix = "raw/" # Apply only to objects under the raw/ prefix
      }
      transitions = [
        {
          days          = var.s3_data_raw_transition_days
          storage_class = "STANDARD_IA"
        },
      ]
    },
    # Add more rules here for /processed, /tiles if defined later
    # {
    #   id = "processed-expiration",
    #   enabled = true,
    #   prefix = "processed/",
    #   expiration = { days = 180 }
    # }
  ]

  # Attach policy for TLS and VPCe enforcement
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_tls_vpce_enforcement.json

  tags = merge(local.tags, {
    Purpose = "data"
    Name    = "${local.name}-data"
  })

  # Ensure KMS key and log bucket exist first
  depends_on = [
    aws_kms_key.s3_key,
    module.s3_log_bucket
  ]
}


################################################################################
# Piksel Notebooks Bucket (Dev)
################################################################################

module "s3_bucket_notebooks_dev" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"

  bucket = "${local.name}-notebooks" # e.g., piksel-dev-notebooks

  # Encryption using the dedicated KMS key
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.arn
      }
      bucket_key_enabled = true
    }
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable versioning
  versioning = {
    enabled = true
  }

  # Configure access logging
  logging = {
    target_bucket = module.s3_log_bucket.s3_bucket_id
    target_prefix = "s3/${local.name}-notebooks/"
  }

  # Lifecycle rules (Expire outputs)
  lifecycle_rule = [
    {
      id      = "outputs-expiration"
      enabled = true
      filter = {
        prefix = "outputs/" # Apply only to objects under the outputs/ prefix
      }
      expiration = {
        days = var.s3_notebook_outputs_expiration_days
      }
    }
  ]

  # Attach policy for TLS and VPCe enforcement
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_tls_vpce_enforcement.json

  tags = merge(local.tags, {
    Purpose = "notebooks"
    Name    = "${local.name}-notebooks"
  })

  # Ensure KMS key and log bucket exist first
  depends_on = [
    aws_kms_key.s3_key,
    module.s3_log_bucket
  ]
}


################################################################################
# Piksel Web Bucket (Dev)
################################################################################

module "s3_bucket_web_dev" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.7.0"

  bucket = "${local.name}-web" # e.g., piksel-dev-web

  # Encryption using the dedicated KMS key
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_key.arn
      }
      bucket_key_enabled = true
    }
  }

  # Block all public access (as specified for dev web bucket)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Disable versioning for web assets
  versioning = {
    enabled = false
  }

  # Configure access logging
  logging = {
    target_bucket = module.s3_log_bucket.s3_bucket_id
    target_prefix = "s3/${local.name}-web/"
  }

  # No lifecycle rules specified for dev web bucket

  # Attach policy for TLS enforcement only
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_tls_only_enforcement.json

  tags = merge(local.tags, {
    Purpose = "web"
    Name    = "${local.name}-web"
  })

  # Ensure KMS key and log bucket exist first
  depends_on = [
    aws_kms_key.s3_key,
    module.s3_log_bucket
  ]
}

# ... (keep existing EKS Cluster SG and Node Group SG resources/modules if they follow) ...
