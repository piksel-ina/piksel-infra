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
