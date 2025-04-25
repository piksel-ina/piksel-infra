# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "vpc_endpoints" {
  description = "VPC Endpoint IDs"
  value = {
    s3      = module.vpc_endpoints.endpoints["s3"].id
    ecr_api = module.vpc_endpoints.endpoints["ecr_api"].id
    ecr_dkr = module.vpc_endpoints.endpoints["ecr_dkr"].id
  }
}

################################################################################

# Security Groups Outputs
output "security_group_ids" {
  description = "Security group IDs for different components"
  value = {
    eks_cluster = aws_security_group.eks_cluster.id
    node_group  = aws_security_group.node_group.id
    alb         = aws_security_group.alb.id
    database    = aws_security_group.database.id
  }
}

################################################################################

# KMS Outputs
output "s3_kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  value       = aws_kms_key.s3_key.arn
}

################################################################################

# S3 Outputs
output "s3_log_bucket_id" {
  description = "ID (name) of the S3 bucket used for access logging"
  value       = module.s3_log_bucket.s3_bucket_id
}

output "s3_bucket_data_dev_id" {
  description = "ID (name) of the S3 data bucket for the dev environment"
  value       = module.s3_bucket_data_dev.s3_bucket_id
}

output "s3_bucket_data_dev_arn" {
  description = "ARN of the S3 data bucket for the dev environment"
  value       = module.s3_bucket_data_dev.s3_bucket_arn
}

output "s3_bucket_notebooks_dev_id" {
  description = "ID (name) of the S3 notebooks bucket for the dev environment"
  value       = module.s3_bucket_notebooks_dev.s3_bucket_id
}

output "s3_bucket_notebooks_dev_arn" {
  description = "ARN of the S3 notebooks bucket for the dev environment"
  value       = module.s3_bucket_notebooks_dev.s3_bucket_arn
}

output "s3_bucket_web_dev_id" {
  description = "ID (name) of the S3 web bucket for the dev environment"
  value       = module.s3_bucket_web_dev.s3_bucket_id
}

output "s3_bucket_web_dev_arn" {
  description = "ARN of the S3 web bucket for the dev environment"
  value       = module.s3_bucket_web_dev.s3_bucket_arn
}
