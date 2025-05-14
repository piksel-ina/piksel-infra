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
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

# -- Availability Zones ---
output "azs" {
  description = "List of Availability Zones used for subnets"
  value       = module.vpc.azs
}

# --- NAT Gateway Outputs ---
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = length(module.vpc.natgw_ids)
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
output "flow_log_id" {
  description = "ID of the VPC Flow Log (if enabled)"
  value       = var.enable_flow_log ? module.vpc.vpc_flow_log_id : "Flow Logs Disabled"
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = var.enable_flow_log ? module.vpc.vpc_flow_log_cloudwatch_iam_role_arn : "Flow Logs Disabled"
}
