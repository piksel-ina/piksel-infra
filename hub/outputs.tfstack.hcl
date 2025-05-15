# --- Data Source ---
output "account_id" {
  type        = string
  description = "The AWS account ID"
  value       = component.vpc.account_id
}

# --- VPC Outputs ---
output "vpc_id" {
  type        = string
  description = "ID of the VPC"
  value       = component.vpc.vpc_id
}

output "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
  value       = component.vpc.vpc_cidr_block
}

# --- Subnet Outputs ---
output "public_subnets" {
  type        = list(string)
  description = "List of IDs of public subnets"
  value       = component.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of public subnets"
  value       = component.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  type        = list(string)
  description = "List of IDs of private subnets"
  value       = component.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of private subnets"
  value       = component.vpc.private_subnets_cidr_blocks
}

# --- NAT Gateway Outputs ---
output "natgw_ids" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.natgw_ids
}

output "nat_public_ips" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.nat_public_ips
}

# --- Route Table Outputs ---
output "public_route_table_ids" {
  type        = list(string)
  description = "List of IDs of public route tables"
  value       = component.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  type        = list(string)
  description = "List of IDs of private route tables"
  value       = component.vpc.private_route_table_ids
}

# Flow Logs Output
output "vpc_flow_log_id" {
  type        = string
  description = "ID of the VPC Flow Log (if enabled)"
  value       = component.vpc.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  type        = string
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = component.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}
