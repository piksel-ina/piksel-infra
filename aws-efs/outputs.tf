# --- Outputs ---
output "efs_file_system_id" {
  description = "ID of the EFS File System"
  value       = aws_efs_file_system.data.id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS File System"
  value       = aws_efs_file_system.data.arn
}

output "efs_security_group_id" {
  description = "ID of the Security Group for EFS"
  value       = aws_security_group.efs.id
}

output "efs_mount_target_ids" {
  description = "List of IDs for EFS Mount Targets"
  value       = aws_efs_mount_target.data[*].id
}

output "public_data_access_point_id" {
  description = "ID of the Public Data Access Point"
  value       = aws_efs_access_point.public_data.id
}

output "public_data_access_point_arn" {
  description = "ARN of the Public Data Access Point"
  value       = aws_efs_access_point.public_data.arn
}

output "coastline_changes_access_point_id" {
  description = "ID of the Coastline Changes Project Access Point"
  value       = aws_efs_access_point.coastline_changes.id
}

output "coastline_changes_access_point_arn" {
  description = "ARN of the Coastline Changes Project Access Point"
  value       = aws_efs_access_point.coastline_changes.arn
}
