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

# --- Flow Logs Output ---
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

# --- Route53 Zone Association Outputs ---
output "private_zone_association_id" {
  type        = list(string)
  description = "The account ID of the account that created the hosted zone"
  value       = component.phz_association.private_zone_association_id
}

# --- Transit Gateway Attachment Outputs ---
output "tgw_attachment_arn" {
  description = "The ARN of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_attachment_arn
}

output "tgw_attachment_id" {
  description = "The ID of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_attachment_id
}

output "tgw_vpc_owner_id" {
  description = "The owner ID of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_vpc_owner_id

}

# --- Route Table Outputs ---
output "spoke_to_shared_vpc_via_tgw_route_id" {
  description = "The ID of the route to the shared VPC via Transit Gateway"
  type        = list(string)
  value       = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_id
}
output "spoke_to_shared_vpc_via_tgw_route_state" {
  description = "The state of the route to the shared VPC via Transit Gateway"
  type        = list(string)
  value       = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_state
}
