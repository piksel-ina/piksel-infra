# --- Output to be consumed by other stacks ---
publish_output "vpc_id_dev" {
  description = "Development VPC ID"
  value       = deployment.development.vpc_id
}

publish_output "vpc_cidr_dev" {
  description = "Development VPC CIDR Block"
  value       = deployment.development.vpc_cidr_block
}

publish_output "phz_association_id_dev" {
  description = "Private Host Zone Association unique identifier"
  value       = deployment.development.private_zone_association_id
}
