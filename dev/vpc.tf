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
