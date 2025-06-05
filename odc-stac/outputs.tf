output "stac_namespace" {
  value = kubernetes_namespace.stac.metadata[0].name
}

output "stac_write_secret_arn" {
  value = aws_secretsmanager_secret.stac_write_password.arn
}

output "stac_read_secret_arn" {
  value = aws_secretsmanager_secret.stacread_password.arn
}

output "stacread_k8s_secret_name" {
  value = kubernetes_secret.stacread_namespace_secret.metadata[0].name
}
