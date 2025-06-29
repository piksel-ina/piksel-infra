# --- Database connection details ---
output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.db.db_instance_endpoint
}

output "db_address" {
  description = "RDS database address (hostname only)"
  value       = split(":", module.db.db_instance_endpoint)[0]
}

output "db_port" {
  description = "RDS database port"
  value       = module.db.db_instance_port
}

output "db_name" {
  description = "Database name"
  value       = local.project
}

output "db_username" {
  description = "Database username"
  value       = local.db_username
  sensitive   = true
}

output "db_password" {
  description = "Database password"
  value       = aws_secretsmanager_secret_version.db_password.secret_string
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = module.db.db_instance_identifier
}

# --- Kubernetes resources ---
output "k8s_db_service" {
  description = "Kubernetes database service FQDN"
  value       = "${kubernetes_service.db_endpoint.metadata[0].name}.${kubernetes_service.db_endpoint.metadata[0].namespace}.svc.cluster.local"
}

output "db_namespace" {
  description = "Database Kubernetes namespace"
  value       = kubernetes_namespace.db.metadata[0].name
}

# --- Security Group Outputs ---
output "security_group_arn_database" {
  description = "The ARN of the security group"
  value       = module.security_group.security_group_arn
}

output "security_group_id_database" {
  description = "The ID of the security group"
  value       = module.security_group.security_group_id
}

output "security_group_name_database" {
  description = "The name of the security group"
  value       = module.security_group.security_group_name
}

output "security_group_description_database" {
  description = "The description of the security group"
  value       = module.security_group.security_group_description
}
