
# --- public zone outputs ---
output "zone_ids" {
  description = "The ID of the public hosted zone"
  value       = module.zones.route53_zone_zone_id
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = module.zones.route53_zone_name_servers
}

output "zone_arn" {
  description = "The ARN of the public hosted zone"
  value       = module.zones.route53_zone_zone_arn
}

output "zone_name" {
  description = "The name of the public hosted zone"
  value       = module.zones.route53_zone_name
}

# --- Resolver Outputs ---
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

// Only include this output if the resolver rule is shared
# output "outbound_resolver_id" {
#   description = "The ID of the Outbound Resolver Endpoint."
#   value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_id
# }

# output "outbound_resolver_ip_addresses" {
#   description = "IP Addresses of the Outbound Resolver Endpoint."
#   value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_ip_addresses
# }

# output "outbound_resolver_security_group_id" {
#   description = "Security Group ID used by the Outbound Resolver Endpoint."
#   value       = module.outbound_resolver_endpoint.route53_resolver_endpoint_security_group_ids
# }
