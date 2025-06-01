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
