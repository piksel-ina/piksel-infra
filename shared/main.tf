# Shared resources configuration
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name     = "${lower(var.project)}-${lower(var.environment)}" # Should evaluate to piksel-shared
  vpc_cidr = var.vpc_cidr
  # Use 3 AZs for high availability
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = merge(var.common_tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

################################################################################
# VPC Module (Shared VPC)
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # Using v5.x as you had previously, ensure compatibility with TGW module version
  version = "5.21.0"

  name = local.name # piksel-shared
  cidr = local.vpc_cidr
  azs  = local.azs

  # Define standard subnets for Shared VPC - Adjust CIDR blocks based on chosen vpc_cidr
  # Using 10.1.0.0/16 and 3 AZs
  public_subnets  = [cidrsubnet(local.vpc_cidr, 8, 0), cidrsubnet(local.vpc_cidr, 8, 1), cidrsubnet(local.vpc_cidr, 8, 2)] # e.g., 10.1.0.0/24, 10.1.1.0/24, 10.1.2.0/24
  private_subnets = [cidrsubnet(local.vpc_cidr, 8, 3), cidrsubnet(local.vpc_cidr, 8, 4), cidrsubnet(local.vpc_cidr, 8, 5)] # e.g., 10.1.3.0/24, 10.1.4.0/24, 10.1.5.0/24

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway configuration - Shared infra should be highly available
  enable_nat_gateway     = true
  single_nat_gateway     = false # Always use HA for shared
  one_nat_gateway_per_az = true

  # VPC Flow Logs configuration
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true # Consider sending to central bucket/log group later
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # Subnet Tags
  public_subnet_tags = {
    Purpose = "Public-NAT"
  }
  private_subnet_tags = {
    Purpose = "Private-Shared-Services"
  }

  tags = local.tags # Apply common tags to VPC and subnets
}

################################################################################
# Transit Gateway Module
################################################################################

module "tgw" {
  source = "terraform-aws-modules/transit-gateway/aws"
  # Choose a recent version, align with example if desired
  version = "~> 2.0" # Or specify a fixed version like "2.13.0"

  name            = "${local.name}-tgw"
  description     = "${local.name} Transit Gateway"
  amazon_side_asn = var.transit_gateway_amazon_side_asn

  enable_auto_accept_shared_attachments  = true # Enable to auto-accept attachments from spoke accounts (via RAM)
  enable_default_route_table_association = true
  enable_default_route_table_propagation = true
  enable_dns_support                     = true # Enable DNS resolution across TGW

  # Configure the attachment to the Shared VPC created above
  vpc_attachments = {
    # Use a descriptive key for the attachment
    shared_vpc = {
      vpc_id = module.vpc.vpc_id
      # Attach TGW to the private subnets of the Shared VPC
      # Ensure these subnets have route tables that allow traffic to the TGW
      subnet_ids = module.vpc.private_subnets
      # Optional: Configure DNS support specifically for this attachment
      # dns_support = true
      # Optional: Configure specific association/propagation for this attachment if needed
      # transit_gateway_default_route_table_association = true
      # transit_gateway_default_route_table_propagation = true
      # Optional: Add tags specific to this attachment
      tags = { Name = "${local.name}-shared-vpc-tgw-attachment" }
    }
  }

  # Configure RAM sharing to share this TGW with other accounts
  ram_allow_external_principals = true
  ram_principals                = var.tgw_ram_principals

  tags = merge(local.tags, {
    Name = "${local.name}-tgw"
  })
}


################################################################################
# VPC Endpoints
################################################################################
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0" # Match VPC module version if possible

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = { # Gateway endpoint for S3 access within VPC
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids # Attach to private route tables
      tags            = { Name = "${local.name}-s3-gw-endpoint" }
    },
    ecr_api = { # Interface endpoint for ECR API calls
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets # Place ENIs in private subnets
      tags                = { Name = "${local.name}-ecr-api-if-endpoint" }
    },
    ecr_dkr = { # Interface endpoint for Docker pulling from ECR
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.name}-ecr-dkr-if-endpoint" }
    },
    sts = { # Interface endpoint for AWS Security Token Service
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.name}-sts-if-endpoint" }
    },
    logs = { # Interface endpoint for CloudWatch Logs
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${local.name}-logs-if-endpoint" }
    },
    # Add others as needed: kms, secretsmanager, ssm, ssmmessages, ec2messages, etc.
  }

  tags = local.tags # Apply common tags to endpoints
}

################################################################################
# Routing (Example: Allow Shared Private Subnets to reach Spoke VPCs via TGW)
# Note: Spoke VPC routes pointing back to Shared VPC via TGW are configured
#       in the respective dev/staging/prod Terraform configurations.
################################################################################

# Explicit routes within the Shared VPC pointing to the TGW might still be needed
# depending on your setup and whether you rely solely on propagation.
# The TGW module typically creates necessary routes in the TGW route tables.
# You might need routes in your *VPC* route tables (e.g., private)
# pointing destination CIDRs (like spoke VPCs) to the TGW.

# Example (if needed): Route traffic destined for Dev VPC (e.g., 10.0.0.0/16) via TGW
# resource "aws_route" "private_to_dev_via_tgw" {
#   count = length(module.vpc.private_route_table_ids)
#
#   route_table_id         = module.vpc.private_route_table_ids[count.index]
#   destination_cidr_block = "10.0.0.0/16" # Replace with actual Dev VPC CIDR
#   # Reference the TGW ID output from the TGW module
#   transit_gateway_id     = module.tgw.ec2_transit_gateway_id
#
#   # Ensure attachment exists before creating route
#   depends_on = [module.tgw]
# }
# Repeat for staging, prod CIDRs...





####################################################################
# GitHub OIDC Provider
####################################################################
module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.55.0"

  create = true
  tags   = local.tags
}

####################################################################
# ECR Repository - Private
####################################################################
module "piksel_core_ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  repository_name = "${lower(var.project)}-ecr"
  # Default is private, but setting explicitly for clarity
  repository_type                 = "private"
  repository_image_tag_mutability = var.ecr_image_tag_mutability

  # Repository lifecycle policy
  create_lifecycle_policy = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only last ${var.ecr_max_tagged_images} tagged images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v", "release"],
          countType     = "imageCountMoreThan",
          countNumber   = var.ecr_max_tagged_images
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images older than ${var.ecr_untagged_image_retention_days} days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = var.ecr_untagged_image_retention_days
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  # Repository policy for access control
  create_repository_policy = true
  repository_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "GithubActionsAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name}-github-actions"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      },
      {
        Sid    = "EKSNodeAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name}-eks-ecr-access"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })

  tags = local.tags
}

####################################################################
# IAM Roles
####################################################################
# GitHub OIDC Role
module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.55.0"

  create_role = true
  role_name   = "${local.name}-github-actions"

  provider_urls                  = [module.github_oidc_provider.url]
  oidc_fully_qualified_subjects  = ["repo:piksel-ina/piksel-core:*"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]

  role_policy_arns = [module.github_actions_ecr_policy.arn]

  tags = local.tags
}

# GitHub Actions ECR Policy
module "github_actions_ecr_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name        = "${local.name}-github-actions-ecr-access"
  description = "IAM policy for GitHub Actions to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = module.piksel_core_ecr.repository_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

# EKS ECR Access Role
module "eks_ecr_access_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.55.0"

  create_role = true
  role_name   = "${local.name}-eks-ecr-access"

  # This will need to be updated once EKS is created
  provider_urls                 = ["oidc.eks.${var.aws_region}.amazonaws.com/id/EXAMPLE12345"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:ecr-access-sa"]

  role_policy_arns = [module.eks_ecr_access_policy.arn]

  tags = local.tags
}

# EKS ECR Access Policy
module "eks_ecr_access_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.55.0"

  name        = "${local.name}-eks-ecr-access"
  description = "IAM policy for EKS to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = module.piksel_core_ecr.repository_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}
