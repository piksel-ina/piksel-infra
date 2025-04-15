# Environment identifier
environment = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Availability Zones - using only 1 AZ for minimal dev costs
azs_to_use = ["ap-southeast-3a"]

# Subnet Configuration - one subnet of each type in the single AZ
public_subnets = {
  "public-ap-southeast-3a" = {
    cidr_block        = "10.0.0.0/24"
    availability_zone = "ap-southeast-3a"
  }
}

private_app_subnets = {
  "private-app-ap-southeast-3a" = {
    cidr_block        = "10.0.10.0/24"
    availability_zone = "ap-southeast-3a"
  }
}

private_data_subnets = {
  "private-data-ap-southeast-3a" = {
    cidr_block        = "10.0.20.0/24"
    availability_zone = "ap-southeast-3a"
  }
}

# NAT Gateway Configuration - single NAT for the single AZ
single_nat_gateway = true

# Common Tags
common_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "Piksel"
  Owner       = "Piksel Dev Team"
}
