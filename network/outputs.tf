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

# --- Route53 Association Outputs ---

output "private_zone_association_owner_id" {
  description = "The account ID of the account that created the hosted zone"
  value       = [for zone in aws_route53_zone_association.vpc_association : zone.owning_account]
}

output "private_zone_association_id" {
  description = "The account ID of the account that created the hosted zone"
  value       = [for zone in aws_route53_zone_association.vpc_association : zone.id]
}

# --- DHCP Options Outputs ---
output "dhcp_options" {
  description = "DHCP Option Outputs"
  value = {
    dhcp_id  = aws_vpc_dhcp_options.spoke_dhcp.id
    dhcp_arn = aws_vpc_dhcp_options.spoke_dhcp.arn
    assoc_id = aws_vpc_dhcp_options_association.spoke_dhcp_assoc.id
  }
}

# --- TGW Attachment Outputs ---
output "tgw_attachment_arn" {
  description = "The ARN of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.arn
}

output "tgw_attachment_id" {
  description = "The ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.id
}

output "tgw_vpc_owner_id" {
  description = "The owner ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.vpc_owner_id
}

# --- Route Table Outputs ---
output "spoke_to_shared_vpc_via_tgw_route_id" {
  description = "The ID of the route to the shared VPC via Transit Gateway"
  value       = [for rtb in aws_route.spoke_to_shared_vpc_via_tgw : rtb.id]
}
output "spoke_to_shared_vpc_via_tgw_route_state" {
  description = "The state of the route to the shared VPC via Transit Gateway"
  value       = [for rtb in aws_route.spoke_to_shared_vpc_via_tgw : rtb.state]
}
