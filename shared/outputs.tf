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

output "ecr_repository_url" {
  description = "The URL of the ECR private repository"
  value       = module.piksel_core_ecr.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR private repository"
  value       = module.piksel_core_ecr.repository_arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for ECR access"
  value       = module.github_actions_role.iam_role_arn
}

output "github_oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = module.github_oidc_provider.url
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github_oidc_provider.arn
}

output "eks_ecr_access_role_arn" {
  description = "ARN of the EKS role for ECR access"
  value       = module.eks_ecr_access_role.iam_role_arn
}


output "public_zone_id" {
  description = "The ID of the public hosted zone"
  value       = module.public_zone.route53_zone_zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone (needed for delegation)"
  value       = module.public_zone.route53_zone_name_servers
}


## Resolver Outputs
output "inbound_resolver_id" {
  description = "The ID of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_id
}

output "inbound_resolver_arn" {
  description = "The ARN of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_arn
}

output "inbound_resolver_ip_addresses" {
  description = "IP Addresses of the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_ip_addresses
}

output "inbound_resolver_security_group_id" {
  description = "Security Group ID used by the Inbound Resolver Endpoint."
  value       = module.inbound_resolver_endpoint.route53_resolver_endpoint_security_group_ids
}

output "outbound_resolver_id" {
  description = "The ID of the Outbound Resolver Endpoint."
  value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_id
}

output "outbound_resolver_ip_addresses" {
  description = "IP Addresses of the Outbound Resolver Endpoint."
  value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_ip_addresses
}

output "outbound_resolver_security_group_id" {
  description = "Security Group ID used by the Outbound Resolver Endpoint."
  value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_security_group_ids
}

output "resolver_rule_id" {
  description = "The ID of the created Route 53 Resolver Rule (from AutomateTheCloud module)."
  value       = module.internal_domains_resolver_rule.metadata.route53_resolver_rule.id
}

output "resolver_rule_arn" {
  description = "The ARN of the created Route 53 Resolver Rule (from AutomateTheCloud module)."
  value       = module.internal_domains_resolver_rule.metadata.route53_resolver_rule.arn
}

output "resolver_rule_name" {
  description = "The actual name of the Route 53 Resolver Rule as created by the module."
  value       = module.internal_domains_resolver_rule.metadata.route53_resolver_rule.name
}

output "ram_resource_share_arn" {
  description = "The ARN of the RAM Resource Share used for this resolver rule (if applicable)."
  value       = try(module.internal_domains_resolver_rule.metadata.ram_resource_share.arn, null)
  # Use try() in case sharing is disabled and ram_resource_share is null
}

output "resolver_rule_association_id" {
  description = "ID of Route53 Resolver rule associations"
  value       = module.resolver_rule_associations.route53_resolver_rule_association_id
}

output "resolver_rule_association_name" {
  description = "Name of Route53 Resolver rule associations"
  value       = module.resolver_rule_associations.route53_resolver_rule_association_name
}

output "resolver_rule_association_resolver_rule_id" {
  description = "ID of Route53 Resolver rule associations resolver rule"
  value       = module.resolver_rule_associations.route53_resolver_rule_association_resolver_rule_id
}
