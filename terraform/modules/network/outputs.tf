output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_app_subnet_ids" {
  description = "Map of private app subnet IDs"
  value       = { for k, v in aws_subnet.private_app : k => v.id }
}

output "private_data_subnet_ids" {
  description = "Map of private data subnet IDs"
  value       = { for k, v in aws_subnet.private_data : k => v.id }
}

output "public_subnet_cidrs" {
  description = "Map of public subnet CIDR blocks"
  value       = { for k, v in aws_subnet.public : k => v.cidr_block }
}

output "private_app_subnet_cidrs" {
  description = "Map of private app subnet CIDR blocks"
  value       = { for k, v in aws_subnet.private_app : k => v.cidr_block }
}

output "private_data_subnet_cidrs" {
  description = "Map of private data subnet CIDR blocks"
  value       = { for k, v in aws_subnet.private_data : k => v.cidr_block }
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs"
  value       = { for k, v in aws_nat_gateway.main : k => v.id }
}

output "nat_gateway_ips" {
  description = "Map of Elastic IP addresses associated with NAT Gateways"
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of private route table IDs"
  value       = { for k, v in aws_route_table.private : k => v.id }
}

output "availability_zones" {
  description = "List of availability zones used"
  value = distinct([
    for subnet in merge(var.public_subnets, var.private_app_subnets, var.private_data_subnets) : subnet.availability_zone
  ])
}

output "nat_gateway_enabled" {
  description = "Whether NAT Gateways are enabled"
  value       = var.enable_nat_gateway
}

# Convenience outputs for common use cases
output "public_subnet_ids_list" {
  description = "List of public subnet IDs (for resources that need a list)"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_app_subnet_ids_list" {
  description = "List of private app subnet IDs (for resources that need a list)"
  value       = [for subnet in aws_subnet.private_app : subnet.id]
}

output "private_data_subnet_ids_list" {
  description = "List of private data subnet IDs (for resources that need a list)"
  value       = [for subnet in aws_subnet.private_data : subnet.id]
}
