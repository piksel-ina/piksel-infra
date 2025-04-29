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
# Security Groups
################################################################################

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules from specified CIDR blocks
  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = join(",", var.allowed_cidr_blocks) # Module expects comma-separated string or list
      description = "Allow HTTP from specified CIDRs"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = join(",", var.allowed_cidr_blocks)
      description = "Allow HTTPS from specified CIDRs"
    }
  ]

  # Egress rules: Allow all outbound
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  tags = merge(local.tags, { Name = "${local.name}-alb-sg" })
}

module "eks_nodes_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  # Ingress from self (node-to-node communication)
  ingress_with_self = [
    {
      rule        = "all-all"
      description = "Allow all traffic from self (node-to-node)"
    }
  ]

  # Ingress rules from other Security Groups
  ingress_with_source_security_group_id = [
    # From Control Plane (Note: This references module.eks_control_plane_sg)
    {
      # Using specific ports/protocol as 'all-all' might not be a predefined rule name
      from_port                = 1025
      to_port                  = 65535
      protocol                 = "tcp"
      source_security_group_id = module.eks_control_plane_sg.security_group_id # Reference potentially causing cycle
      description              = "Allow Kubelet API from Control Plane"
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.eks_control_plane_sg.security_group_id # Reference potentially causing cycle
      description              = "Allow HTTPS from Control Plane"
    },
    # From ALB
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Allow HTTP from ALB"
    },
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Allow HTTPS from ALB"
    }
  ]

  # Egress rules: Allow all outbound
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  tags = merge(local.tags, { Name = "${local.name}-eks-nodes-sg" })

  # Explicit dependency might help Terraform's graph, but could also formalize a cycle
  # depends_on = [module.eks_control_plane_sg, module.alb_sg]
}

module "eks_control_plane_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-eks-control-plane-sg"
  description = "Security group for EKS control plane"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules from other Security Groups
  ingress_with_source_security_group_id = [
    # From EKS Nodes (Note: This references module.eks_nodes_sg)
    {
      rule                     = "https-443-tcp"
      source_security_group_id = module.eks_nodes_sg.security_group_id # Reference potentially causing cycle
      description              = "Allow HTTPS from EKS Nodes"
    },
    {
      # Allow all traffic from nodes (as per original config) - Be cautious with this rule
      rule                     = "all-all"
      source_security_group_id = module.eks_nodes_sg.security_group_id # Reference potentially causing cycle
      description              = "Allow ALL traffic from EKS Nodes (Review if needed)"
    }
  ]

  # Egress rules: Allow all outbound
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  tags = merge(local.tags, { Name = "${local.name}-eks-control-plane-sg" })

  # Explicit dependency might help Terraform's graph, but could also formalize a cycle
  # depends_on = [module.eks_nodes_sg]
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name}-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules from other Security Groups
  ingress_with_source_security_group_id = [
    # From EKS Nodes
    {
      # Using specific ports/protocol as 'postgresql-tcp' might not be a predefined rule name
      from_port                = 5432 # Assuming PostgreSQL default port
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.eks_nodes_sg.security_group_id
      description              = "Allow PostgreSQL access from EKS Nodes"
    }
  ]

  # Egress rules: Allow all outbound
  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })

  depends_on = [module.eks_nodes_sg] # Explicit dependency is safe here as RDS depends on Nodes, but not vice-versa
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

# For data bucket
data "aws_iam_policy_document" "data_bucket_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.name}-data/*",
      "arn:aws:s3:::${local.name}-data"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# For notebooks bucket
data "aws_iam_policy_document" "notebooks_bucket_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.name}-notebooks/*",
      "arn:aws:s3:::${local.name}-notebooks"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "s3_tls_only_enforcement" {
  # Policy for buckets requiring TLS
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
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
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
  # Use a simple TLS-only policy for now
  attach_policy = true
  policy        = data.aws_iam_policy_document.data_bucket_policy.json

  tags = merge(local.tags, {
    Purpose = "data"
    Name    = "${local.name}-data"
  })

  # Ensure KMS key and log bucket exist first
  depends_on = [
    aws_kms_key.s3_key,
    module.s3_log_bucket
  ]

  # # Intelligent Tiering for data bucket
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

  # Use a simple TLS-only policy for now
  attach_policy = true
  policy        = data.aws_iam_policy_document.notebooks_bucket_policy.json

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
    attach_policy                   = true
    attach_policy_for_cfn           = true
    cfn_origin_access_identity_path = null # Not needed when using OAC
    cfn_distribution_arn            = module.cloudfront.cloudfront_distribution_arn

    # Additional TLS enforcement policy
    attach_policy_for_tls = true
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

################################################################################
# CloudFront for Web Bucket
################################################################################

# ACM Certificate (only created if custom domain is used)
resource "aws_acm_certificate" "web_cert" {
  count             = var.use_custom_domain && var.create_acm_certificate ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-web-cert"
  })
}

# Certificate validation placeholder
resource "aws_acm_certificate_validation" "web_cert" {
  count           = var.use_custom_domain && var.create_acm_certificate ? 1 : 0
  certificate_arn = aws_acm_certificate.web_cert[0].arn
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "4.1.0"

  aliases = var.use_custom_domain ? [var.domain_name] : []

  comment             = "${local.name} web distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"

  # Create Origin Access Control using the module
  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # Origin configuration
  origin = {
    s3_bucket = {
      domain_name           = module.s3_bucket_web_dev.s3_bucket_bucket_regional_domain_name
      origin_access_control = "s3_oac"
      origin_id             = "s3"
    }
  }

  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    # Using managed policies by name (module handles the ARNs)
    use_forwarded_values       = false
    cache_policy_name          = "Managed-CachingOptimized"
    origin_request_policy_name = "Managed-CORS-S3Origin"
  }

  # Custom error responses
  custom_error_response = [
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    },
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 10
    }
  ]

  # Viewer certificate configuration
  viewer_certificate = {
    acm_certificate_arn            = var.use_custom_domain && var.create_acm_certificate ? aws_acm_certificate.web_cert[0].arn : null
    cloudfront_default_certificate = !var.use_custom_domain
    minimum_protocol_version       = var.use_custom_domain ? "TLSv1.2_2021" : "TLSv1"
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
  }

  # No geo-restrictions for dev
  geo_restriction = {
    restriction_type = "none"
  }

  # Enable CloudFront monitoring
  create_monitoring_subscription = true

  # Web Application Firewall (optional)
  web_acl_id = null # Set to WAF WebACL ID if needed

  tags = merge(local.tags, {
    Name    = "${local.name}-web-distribution"
    Purpose = "web"
  })

  depends_on = [
    aws_acm_certificate_validation.web_cert
  ]
}
