output "jupyterhub_namespace" {
  description = "The namespace where JupyterHub is deployed"
  value       = kubernetes_namespace.hub.metadata[0].name
}

output "jupyterhub_subdomain" {
  description = "The public subdomain for JupyterHub"
  value       = local.jhub_subdomain
}

output "jupyterhub_db_secret_arn" {
  description = "ARN of the JupyterHub database password secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.jupyterhub_password.arn
}

output "jupyterhub_irsa_arn" {
  description = "IAM Role ARN for JupyterHub user-read service account (IRSA)"
  value       = module.iam_eks_role_hub_reader.iam_role_arn
}

output "jupyterhub_service_account_name" {
  description = "Kubernetes service account name for S3 read access"
  value       = kubernetes_service_account.hub_user_read.metadata[0].name
}
