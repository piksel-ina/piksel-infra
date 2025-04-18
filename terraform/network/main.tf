provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "Piksel"
      Environment = var.environment
    }
  }
}

module "network" {
  source = "./modules/network"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  # AZ configuration
  azs_to_use         = var.azs_to_use
  single_nat_gateway = var.single_nat_gateway
  enable_nat_gateway = var.enable_nat_gateway

  # Subnet configurations
  public_subnets       = var.public_subnets
  private_app_subnets  = var.private_app_subnets
  private_data_subnets = var.private_data_subnets

  # For EKS integration in the future
  cluster_name = var.cluster_name

  # Common tags to apply to all resources
  common_tags = var.common_tags
}
