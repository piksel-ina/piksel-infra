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
    # Updated to use module outputs
    eks_cluster = module.eks_control_plane_sg.security_group_id # Assuming module name from previous refactor
    node_group  = module.eks_nodes_sg.security_group_id         # Assuming module name from previous refactor
    alb         = module.alb_sg.security_group_id               # Assuming module name from previous refactor
    database    = module.rds_sg.security_group_id               # Assuming module name from previous refactor
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

output "s3_bucket_data_id" {
  description = "ID (name) of the S3 data bucket"
  value       = module.s3_bucket_data.s3_bucket_id
}

output "s3_bucket_data_arn" {
  description = "ARN of the S3 data bucket"
  value       = module.s3_bucket_data.s3_bucket_arn
}

output "s3_bucket_notebooks_id" {
  description = "ID (name) of the S3 notebooks bucket"
  value       = module.s3_bucket_notebooks.s3_bucket_id
}

output "s3_bucket_notebooks_arn" {
  description = "ARN of the S3 notebooks bucket"
  value       = module.s3_bucket_notebooks.s3_bucket_arn
}

output "s3_bucket_web_id" {
  description = "ID (name) of the S3 web bucket"
  value       = module.s3_bucket_web.s3_bucket_id
}

output "s3_bucket_web_arn" {
  description = "ARN of the S3 web bucket"
  value       = module.s3_bucket_web.s3_bucket_arn
}

# Cloudfront Outputs
output "custom_domain_url" {
  description = "The custom domain URL (if configured)"
  value       = var.use_custom_domain ? "https://${var.domain_name}" : "No custom domain configured"
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_url" {
  description = "The URL of the CloudFront distribution"
  value       = "https://${module.cloudfront.cloudfront_distribution_domain_name}"
}


# ------------------------------------------------------------------------------
# RDS - ODC Index Database Outputs
# ------------------------------------------------------------------------------
output "odc_rds_instance_id" {
  description = "The ID of the ODC index RDS instance."
  value       = module.odc_rds.db_instance_identifier
}

output "odc_rds_instance_arn" {
  description = "The ARN of the ODC index RDS instance."
  value       = module.odc_rds.db_instance_arn
}

output "odc_rds_instance_endpoint" {
  description = "The connection endpoint for the ODC index RDS instance."
  value       = module.odc_rds.db_instance_endpoint
}

output "odc_rds_instance_port" {
  description = "The port the ODC index RDS instance is listening on."
  value       = module.odc_rds.db_instance_port
}

output "odc_rds_instance_address" {
  description = "The address of the ODC index RDS instance."
  value       = module.odc_rds.db_instance_address
}

output "odc_rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the master credentials for the ODC index RDS."
  value       = try(module.odc_rds.db_instance_master_user_secret[0].secret_arn, null) # Access secret ARN safely
  sensitive   = true
}

output "odc_rds_security_group_id" {
  description = "The ID of the security group attached to the ODC index RDS instance."
  value       = module.rds_sg.security_group_id
}
