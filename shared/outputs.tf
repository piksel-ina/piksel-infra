# VPC Outputs
output "vpc_id" {
  description = "The ID of the Shared VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the Shared VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets in the Shared VPC"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets in the Shared VPC"
  value       = module.vpc.public_subnets
}

# Use the actual subnets designated for TGW attachments (often private)
output "transit_gateway_subnets" {
  description = "List of IDs of private subnets used for TGW attachments in the Shared VPC" # Adjust description if needed
  value       = module.vpc.private_subnets                                                  # Change if you used different subnets (e.g., public_subnets or a dedicated set)
}

# Transit Gateway Outputs (Assuming TGW is created via module "tgw")
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_id # Reference the module output
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = module.tgw.ec2_transit_gateway_arn # Reference the module output
}

output "transit_gateway_vpc_attachment_ids" {
  description = "List of Transit Gateway VPC Attachment identifiers"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment_ids
}

output "transit_gateway_vpc_attachment" {
  description = "Map of Transit Gateway VPC Attachment attributes"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment
}


# VPC Endpoint Outputs
output "vpc_endpoint_ids" {
  description = "Map of VPC Endpoint IDs created in the Shared VPC"
  value = {
    for k, v in module.vpc_endpoints.endpoints : k => v.id
  }
}

output "vpc_endpoint_dns_entry" {
  description = "Map of VPC Endpoint DNS entries"
  value = {
    for k, v in module.vpc_endpoints.endpoints : k => v.dns_entry if v.dns_entry != null
  }
}

output "vpc_endpoint_network_interface_ids" {
  description = "Map of VPC Endpoint Network Interface IDs"
  value = {
    for k, v in module.vpc_endpoints.endpoints : k => v.network_interface_ids if v.network_interface_ids != null
  }
}
