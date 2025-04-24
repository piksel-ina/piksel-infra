aws_region          = "ap-southeast-3"
project             = "piksel"
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
allowed_cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
common_tags = {
  Project     = "Piksel"
  Environment = "Dev"
  ManagedBy   = "Terraform"
  Owner       = "DevOps-Team"
}
