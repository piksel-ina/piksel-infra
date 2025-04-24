locals {
  name     = "${var.project}-${var.environment}"
  region   = var.aws_region
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = merge(var.common_tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
