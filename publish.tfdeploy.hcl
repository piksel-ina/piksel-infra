# --- Output to be consumed by other stacks ---
publish_output "vpc_id_dev" {
  description = "Development VPC ID"
  value       = deployment.development.vpc_id
}

publish_output "vpc_cidr_dev" {
  description = "Development VPC CIDR Block"
  value       = deployment.development.vpc_cidr_block
}
