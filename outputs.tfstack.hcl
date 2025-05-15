# --- VPC Outputs ---
output "vpc_id" {
  type        = string
  description = "ID of the VPC"
  value       = component.vpc.vpc_id
}
