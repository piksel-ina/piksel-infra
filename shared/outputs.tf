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



output "resolver_rule_arn" {
  description = "ARN of the shared Route53 Resolver Rule for internal domains"
  value       = aws_route53_resolver_rule.central_internal_domains_rule.arn
}
