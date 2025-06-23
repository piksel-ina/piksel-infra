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

# --- JupyterHub Outputs ---
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

output "jupyterhub_db_password" {
  description = "The JupyterHub database password"
  value       = aws_secretsmanager_secret_version.jupyterhub_password.secret_string
  sensitive   = true
}

output "jupyterhub_irsa_arn" {
  description = "IAM Role ARN for JupyterHub user-read service account (IRSA)"
  value       = module.iam_eks_role_hub_reader.iam_role_arn
}

output "jupyterhub_service_account_name" {
  description = "Kubernetes service account name for S3 read access"
  value       = kubernetes_service_account.hub_user_read.metadata[0].name
}

# --- ODC Outputs ---
output "odc_namespace" {
  value       = kubernetes_namespace.odc.metadata[0].name
  description = "Kubernetes namespace for ODC"
}

output "odc_write_password_secret_arn" {
  value       = aws_secretsmanager_secret.odc_write_password.arn
  description = "Secrets Manager ARN for ODC write password"
}

output "odc_read_password_secret_arn" {
  value       = aws_secretsmanager_secret.odc_read_password.arn
  description = "Secrets Manager ARN for ODC read password"
}

output "ows_cache_cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.ows_cache.domain_name
  description = "CloudFront distribution domain name for ows cache"
}

output "ows_cache_cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.ows_cache.id
  description = "CloudFront distribution ID"
}

output "ows_cache_certificate_arn" {
  value       = aws_acm_certificate.ows_cache.arn
  description = "ARN of the ACM certificate for ows cache"
}

output "ows_cache_dns_record" {
  value       = aws_route53_record.ows_cache.fqdn
  description = "FQDN of the Route53 record for ows cache"
}

output "odc_data_reader_role_arn" {
  value       = module.iam_eks_role_bucket.iam_role_arn
  description = "IAM role ARN for ODC data reader"
}
