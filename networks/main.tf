data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  prefix               = "${lower(var.project)}-${lower(var.environment)}"
  cidr                 = var.vpc_cidr
  az_count             = var.az_count
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_names  = [for az in local.azs : "${local.prefix}-public-subnet-${trimprefix(az, "ap-southeast-")}"]
  private_subnet_names = [for az in local.azs : "${local.prefix}-private-subnet-${trimprefix(az, "ap-southeast-")}"]
  tags                 = var.default_tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${local.prefix}-vpc"
  cidr = local.cidr
  azs  = local.azs

  # Subnet CIDR blocks
  public_subnets  = [for i in range(local.az_count) : cidrsubnet(local.cidr, var.public_subnet_bits, i)]
  private_subnets = [for i in range(local.az_count) : cidrsubnet(local.cidr, var.private_subnet_bits, i + local.az_count)]

  # Subnet naming
  public_subnet_names  = local.public_subnet_names
  private_subnet_names = local.private_subnet_names

  # DNS Support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # VPC Flow Logs configuration
  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_name_prefix       = "${local.prefix}-flow-log"
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_days
  create_flow_log_cloudwatch_iam_role             = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.prefix}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.prefix}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.prefix}-default" }

  # Essential EKS tags
  public_subnet_tags = {
    "SubnetType"             = "Public"
    "kubernetes.io/role/elb" = 1
    "karpenter.sh/discovery" = var.cluster_name
  }

  private_subnet_tags = {
    "SubnetType"                                = "Private"
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = 1
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  tags = local.tags
}

resource "aws_subnet" "public_large" {
  count                   = local.az_count
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet(local.cidr, 6, count.index + 4) # /22 = 1024 IPs
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    {
      Name                     = "${local.prefix}-public-large-${trimprefix(local.azs[count.index], "ap-southeast-")}"
      SubnetType               = "Public"
      "kubernetes.io/role/elb" = 1
      "karpenter.sh/discovery" = var.cluster_name
    }
  )
}

resource "aws_route_table_association" "public_large" {
  count          = local.az_count
  subnet_id      = aws_subnet.public_large[count.index].id
  route_table_id = module.vpc.public_route_table_ids[0]
}
