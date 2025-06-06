output "stac_namespace" {
  description = "Kubernetes namespace where STAC is deployed."
  value       = kubernetes_namespace.stac.metadata[0].name
}

output "stac_write_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for STAC write credentials."
  value       = aws_secretsmanager_secret.stac_write_password.arn
}

output "stac_read_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for STAC read credentials."
  value       = aws_secretsmanager_secret.stacread_password.arn
}

output "stac_write_db_password" {
  description = "STAC write database password."
  value       = aws_secretsmanager_secret_version.stac_write_password.secret_string
  sensitive   = true
}

output "stac_read_db_password" {
  description = "STAC read database password."
  value       = aws_secretsmanager_secret_version.stacread_password.secret_string
  sensitive   = true
}

output "stacread_k8s_secret_name" {
  description = "Kubernetes secret name for STAC read credentials."
  value       = kubernetes_secret.stacread_namespace_secret.metadata[0].name
}
