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
