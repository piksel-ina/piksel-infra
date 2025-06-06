output "grafana_namespace" {
  description = "The Kubernetes namespace where Grafana is deployed."
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_iam_role_arn" {
  description = "The IAM role ARN used by Grafana for IRSA (CloudWatch access)."
  value       = aws_iam_role.grafana.arn
}

output "grafana_cloudwatch_policy_arn" {
  description = "The IAM policy ARN attached to Grafana for CloudWatch access."
  value       = aws_iam_policy.grafana_cloudwatch.arn
}

output "grafana_admin_secret_name" {
  description = "The name of the Kubernetes secret storing the Grafana admin credentials."
  value       = kubernetes_secret.grafana_admin_credentials.metadata[0].name
}

output "grafana_values_secret_name" {
  description = "The name of the Kubernetes secret containing the Grafana Helm values."
  value       = kubernetes_secret.grafana.metadata[0].name
}

output "grafana_db_password_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret storing the Grafana DB password."
  value       = aws_secretsmanager_secret.grafana_password.arn
}

output "grafana_db_password" {
  description = "The Grafana database password."
  value       = aws_secretsmanager_secret_version.grafana_password.secret_string
  sensitive   = true
}

output "grafana_oauth_client_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret for the Grafana OAuth client/secret."
  value       = data.aws_secretsmanager_secret_version.grafana_client_secret.arn
}
