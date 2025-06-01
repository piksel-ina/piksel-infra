# --- Security Group 1 Outputs ---
output "security_group_arn_hub_to_spoke" {
  description = "The ARN of the security group"
  value       = module.spoke_sg.security_group_arn
}

output "security_group_id_hub_to_spoke" {
  description = "The ID of the security group"
  value       = module.spoke_sg.security_group_id
}

output "security_group_name_hub_to_spoke" {
  description = "The name of the security group"
  value       = module.spoke_sg.security_group_name
}

output "security_group_description_hub_to_spoke" {
  description = "The description of the security group"
  value       = module.spoke_sg.security_group_description
}

# --- Security Group 2 Outputs ---
output "security_group_arn_database" {
  description = "The ARN of the security group"
  value       = module.spoke_sg.security_group_arn
}

output "security_group_id_database" {
  description = "The ID of the security group"
  value       = module.spoke_sg.security_group_id
}

output "security_group_name_database" {
  description = "The name of the security group"
  value       = module.spoke_sg.security_group_name
}

output "security_group_description_database" {
  description = "The description of the security group"
  value       = module.spoke_sg.security_group_description
}
