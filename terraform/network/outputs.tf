output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Map of private application subnet IDs"
  value       = module.network.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "Map of private data subnet IDs"
  value       = module.network.private_data_subnet_ids
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs"
  value       = module.network.nat_gateway_ids
}

output "nat_public_ips" {
  value = values(module.network.nat_gateway_ips)
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.network.public_route_table_id
}

output "private_route_table_ids" {
  description = "Map of private route table IDs"
  value       = module.network.private_route_table_ids
}

output "environment" {
  description = "The environment this network belongs to"
  value       = var.environment
}

output "availability_zones" {
  description = "List of availability zones used by the VPC subnets"
  value       = var.azs_to_use
}

output "network_summary" {
  description = "Summary of network configuration"
  value = {
    environment                = var.environment
    vpc_id                     = module.network.vpc_id
    vpc_cidr                   = module.network.vpc_cidr
    public_subnets_count       = length(module.network.public_subnet_ids)
    private_app_subnets_count  = length(module.network.private_app_subnet_ids)
    private_data_subnets_count = length(module.network.private_data_subnet_ids)
    nat_gateways_count         = length(module.network.nat_gateway_ids)
    single_nat_gateway         = var.single_nat_gateway
  }
}
