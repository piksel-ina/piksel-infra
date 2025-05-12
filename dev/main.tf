data "aws_availability_zones" "available" {}

data "terraform_remote_state" "shared" {
  backend = "remote"
  config = {
    organization = "piksel-ina"
    workspaces = {
      name = "piksel-infra-shared"
    }
  }
}


locals {
  name     = "${lower(var.project)}-${lower(var.environment)}" # Should evaluate to piksel-dev
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = merge(var.common_tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
  # Outputs from Shared Services
  shared_tgw_id   = data.terraform_remote_state.shared.outputs.transit_gateway_id
  shared_vpc_cidr = data.terraform_remote_state.shared.outputs.vpc_cidr_block
  # shared_inbound_resolver_ips_list = data.terraform_remote_state.shared.outputs.internal_domains_target_ips_list
  shared_resolver_rule_id = data.terraform_remote_state.shared.outputs.resolver_rule_id
  shared_phz_dev_id       = data.terraform_remote_state.shared.outputs.private_zone_id_dev
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
  public_subnets   = ["10.0.16.0/22", "10.0.80.0/22"] # Public subnets for NAT Gateway, ALB
  private_subnets  = ["10.0.0.0/20", "10.0.64.0/20"]  # Private app subnets for EKS nodes
  database_subnets = ["10.0.20.0/23", "10.0.84.0/23"] # Private data subnets for RDS, ElastiCache
  # public_subnets   = ["10.0.144.0/22"] # AZ 3 CIDR allocation
  # private_subnets  = ["10.0.128.0/20" ] # AZ 3 CIDR allocation
  # database_subnets = ["10.0.148.0/23" ] # AZ 3 CIDR allocation

  # Subnet naming
  public_subnet_names   = ["Public Subnet A", "Public Subnet B"]
  private_subnet_names  = ["Private App Subnet A", "Private App Subnet B"]
  database_subnet_names = ["Private Data Subnet A", "Private Data Subnet B"]

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway_enabled     # Use single NAT for dev/staging, multiple for prod
  one_nat_gateway_per_az = var.one_nat_gateway_per_az_enabled # One NAT per AZ for prod as per network.md

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
# TGW Attachment for Spoke VPC
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_to_shared_tgw" {

  transit_gateway_id = local.shared_tgw_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets # Attach to private subnets

  dns_support = "enable"

  tags = merge(local.tags, {
    Name = "${local.name}-tgw-attachment"
  })
}

################################################################################
# Spoke VPC Route Table Configuration
################################################################################

# Add a route to the Shared Services VPC CIDR via the TGW
# This is for general traffic to the shared VPC, including DNS queries to the resolver endpoints
resource "aws_route" "spoke_to_shared_vpc_via_tgw" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = local.shared_vpc_cidr
  transit_gateway_id     = local.shared_tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw]
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
# Piksel Data Bucket
################################################################################

module "s3_bucket_data" {
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
    {
      id      = "expire-noncurrent-versions"
      enabled = true
      # Apply to all objects in the bucket (empty prefix)
      filter = {
        prefix = ""
      }
      noncurrent_version_expiration = {
        noncurrent_days = var.s3_noncurrent_version_retention_days
      }
    }
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
# Piksel Notebooks Bucket
################################################################################

module "s3_bucket_notebooks" {
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
    },
    {
      id      = "expire-noncurrent-versions"
      enabled = true
      # Apply to all objects in the bucket (empty prefix)
      filter = {
        prefix = ""
      }
      noncurrent_version_expiration = {
        noncurrent_days = var.s3_noncurrent_version_retention_days
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
# Piksel Web Bucket
################################################################################

module "s3_bucket_web" {
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
      domain_name           = module.s3_bucket_web.s3_bucket_bucket_regional_domain_name
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

################################################################################
# RDS - ODC Index Database Resources
################################################################################

module "odc_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "${local.name}-odc-index-rds"

  engine               = "postgres"
  engine_version       = var.odc_db_engine_version
  family               = "postgres17" # Parameter group family must match major engine version
  major_engine_version = "17"         # Option group major engine version must match

  instance_class        = var.odc_db_instance_class
  allocated_storage     = var.odc_db_allocated_storage
  max_allocated_storage = var.odc_db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true # Enable encryption at rest
  kms_key_id            = null # Use default aws/rds KMS key

  db_name                       = var.odc_db_name
  username                      = var.odc_db_master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = null

  port                   = 5432
  multi_az               = var.odc_db_multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  # Parameter Group to enforce SSL
  parameter_group_name = "${local.name}-odc-rds-params-pg17"
  parameters = [
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    }
  ]

  # Option Group (Required for extensions like PostGIS)
  option_group_name = "${local.name}-odc-rds-options-og17"
  options = [
    {
      option_name = "POSTGIS"
    }
  ]

  # Backup and Maintenance
  backup_retention_period = var.odc_db_backup_retention_period
  skip_final_snapshot     = var.odc_db_skip_final_snapshot
  deletion_protection     = var.odc_db_deletion_protection
  apply_immediately       = true

  # Monitoring and Logging
  create_monitoring_role          = true
  monitoring_interval             = 60
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Security
  iam_database_authentication_enabled = true
  publicly_accessible                 = false

  tags = merge(local.tags, { Purpose = "odc-index" })

  # Ensure SG is created before RDS tries to use it
  depends_on = [module.rds_sg]
}


################################################################################
# SNS Notifications for Monitoring Alerts
################################################################################

resource "aws_sns_topic" "monitoring_alerts" {
  name = "${local.name}-monitoring-alerts" # Using local.name assumed from your example

  tags = merge(local.tags, { # Assuming local.tags exists
    Purpose = "MonitoringAlerts"
  })
}

resource "aws_sns_topic_subscription" "email_alert_subscriptions" {
  # Create one subscription for each email in the map
  for_each = var.monitoring_alert_emails

  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = each.value # The email address from the map
}

# IMPORTANT: After applying this configuration, each email address listed
# in var.monitoring_alert_emails will receive a confirmation email from AWS.
# Users MUST click the link in that email to activate the subscription.

################################################################################
# RDS Performance Alarms
################################################################################
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${module.odc_rds.db_instance_identifier}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2 # Breached for 2 consecutive periods (e.g., 10 mins if period is 300s)
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # Check every 5 minutes
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold # Use variable

  dimensions = {
    DBInstanceIdentifier = module.odc_rds.db_instance_identifier # Get ID from module output
  }

  alarm_description = "Alarm when RDS CPU utilization exceeds ${var.rds_cpu_threshold}%"
  alarm_actions     = [aws_sns_topic.monitoring_alerts.arn] # Send alert to SNS
  ok_actions        = [aws_sns_topic.monitoring_alerts.arn] # Notify when OK

  tags = merge(local.tags, { Purpose = "MonitoringAlarm-RDS-CPU" })
}

# 2b. RDS Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${module.odc_rds.db_instance_identifier}-low-free-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1 # Alert immediately on first breach
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300       # Check every 5 minutes
  statistic           = "Minimum" # Check the lowest value in the period
  # Convert GB threshold to Bytes for the alarm
  threshold = var.rds_low_storage_threshold_gb * 1024 * 1024 * 1024

  dimensions = {
    DBInstanceIdentifier = module.odc_rds.db_instance_identifier
  }

  alarm_description = "Alarm when RDS free storage space drops below ${var.rds_low_storage_threshold_gb} GB"
  alarm_actions     = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions        = [aws_sns_topic.monitoring_alerts.arn]

  tags = merge(local.tags, { Purpose = "MonitoringAlarm-RDS-Storage" })
}

# 2c. RDS Freeable Memory Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_memory" {
  alarm_name          = "${module.odc_rds.db_instance_identifier}-low-freeable-memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2 # Low for 2 consecutive periods (e.g., 10 mins)
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300 # Check every 5 minutes
  statistic           = "Minimum"
  # Convert MB threshold to Bytes for the alarm
  threshold = var.rds_low_memory_threshold_mb * 1024 * 1024

  dimensions = {
    DBInstanceIdentifier = module.odc_rds.db_instance_identifier
  }

  alarm_description = "Alarm when RDS freeable memory drops below ${var.rds_low_memory_threshold_mb} MB"
  alarm_actions     = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions        = [aws_sns_topic.monitoring_alerts.arn]

  tags = merge(local.tags, { Purpose = "MonitoringAlarm-RDS-Memory" })
}

################################################################################
# S3 Bucket 5xx Error Alarms
################################################################################
# Define the list of critical bucket names/references to monitor
locals {
  critical_s3_bucket_refs = {
    "data"      = module.s3_bucket_data.s3_bucket_id
    "notebooks" = module.s3_bucket_notebooks.s3_bucket_id
    "web"       = module.s3_bucket_web.s3_bucket_id
  }
}

#  Enable S3 Request Metrics for Critical Buckets
resource "aws_s3_bucket_metric" "critical_bucket_metrics" {
  for_each = local.critical_s3_bucket_refs

  bucket = each.value
  name   = "EntireBucket" # This is the FilterId the alarm will use
  # No filter {} block means it applies to the entire bucket
}

# Create 5xx Error Alarms for Critical Buckets
resource "aws_cloudwatch_metric_alarm" "s3_5xx_errors" {
  for_each = local.critical_s3_bucket_refs

  alarm_name          = "s3-${each.key}-bucket-5xx-errors" # e.g., s3-data-bucket-5xx-errors
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1 # Alert on first occurrence
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 300   # Check every 5 minutes
  statistic           = "Sum" # Total count of 5xx errors in the period
  threshold           = 0     # Alert if ANY 5xx errors occur

  dimensions = {
    BucketName = each.value
    FilterId   = aws_s3_bucket_metric.critical_bucket_metrics[each.key].name # Reference the FilterId created above
  }

  alarm_description = "Alarm when S3 bucket ${each.value} experiences 5xx server errors."
  alarm_actions     = [aws_sns_topic.monitoring_alerts.arn] # Reference the SNS topic defined earlier
  ok_actions        = [aws_sns_topic.monitoring_alerts.arn]

  tags = merge(local.tags, { Purpose = "MonitoringAlarm-S3-5xx-${each.key}" })

  # Explicit dependency to ensure metric config exists before alarm tries to use it
  depends_on = [aws_s3_bucket_metric.critical_bucket_metrics]
}


################################################################################
# IAM Access Analyzer
################################################################################

# Creates an analyzer scoped to this specific AWS account/environment.
resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "${local.name}-analyzer"

  # Analyze resources only within this account
  type = "ACCOUNT"

  # Apply standard tags from locals.tags and add a specific Name tag
  tags = merge(local.tags, {
    Name = "${local.name}-analyzer"
  })
}

################################################################################
# Resolver Rule Association
################################################################################
module "resolver_rule_associations" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-rule-associations"
  version = "~> 5.0"
  create  = true

  resolver_rule_associations = {
    "dev_vpc_association" = {
      resolver_rule_id = local.shared_resolver_rule_id
      vpc_id           = module.vpc.vpc_id
      name             = "piksel-dev-vpc-rule-assoc"
    }
  }

}

#################################################################################
# Route53 Zone Association
#################################################################################
resource "aws_route53_zone_association" "dev_phz_vpc_association" {
  count = length(local.shared_phz_dev_id) > 0 ? 1 : 0

  zone_id    = local.shared_phz_dev_id
  vpc_id     = module.vpc.vpc_id
  vpc_region = var.aws_region
  depends_on = [module.vpc]
}
