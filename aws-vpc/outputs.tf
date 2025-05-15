# --- Account Identifier ---
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# --- VPC Outputs ---
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.vpc.name
}

# --- Subnet Outputs ---
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

# -- Availability Zones ---
output "azs" {
  description = "List of Availability Zones used for subnets"
  value       = module.vpc.azs
}

# --- NAT Gateway Outputs ---
output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = module.vpc.nat_public_ips
}

# --- Route Table Outputs ---
output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

# Flow Logs Output
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log (if enabled)"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}
