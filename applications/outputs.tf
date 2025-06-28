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
  value       = module.iam_eks_role_bucket_odc.iam_role_arn
  description = "IAM role ARN for ODC data reader"
}

# --- ODC-Stac Output ---
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

# --- Terria Output ---
output "terria_bucket_name" {
  description = "The name of the S3 bucket for Terria."
  value       = aws_s3_bucket.terria_bucket.id
}

output "terria_iam_user_name" {
  description = "The IAM user that can access the bucket."
  value       = aws_iam_user.terria_user.name
}

output "terria_k8s_secret_name" {
  description = "Kubernetes secret containing bucket credentials."
  value       = kubernetes_secret.terria_secret.metadata[0].name
}

output "terria_k8s_namespace" {
  description = "Kubernetes namespace where the secret is stored."
  value       = kubernetes_namespace.terria.metadata[0].name
}

# --- Flux outputs ---
output "flux_namespace" {
  description = "The namespace where Flux is deployed"
  value       = kubernetes_namespace.flux_system.metadata[0].name
}

output "slack_webhook_secret_name" {
  description = "Slack webhook secret name"
  value       = kubernetes_secret.slack_webhook.metadata[0].name
}

output "slack_webhook_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret for the Slack Webhook."
  value       = data.aws_secretsmanager_secret_version.slack_webhook.arn
}

# --- Argo-workflow outputs ---
output "argo_artifact_bucket_name" {
  description = "The name of the S3 bucket for Argo artifacts."
  value       = aws_s3_bucket.argo.bucket
}

output "argo_workflow_namespace" {
  description = "The namespace for all Argo resources."
  value       = local.argo_namespace
}

output "argo_artifact_iam_role_arn" {
  description = "The ARN of the IAM role assumed by the Argo artifact service account (IRSA)."
  value       = aws_iam_role.argo_workflow_role.arn
}

output "argo_artifact_iam_policy_arn" {
  description = "The ARN of the IAM policy for S3 read/write access."
  value       = aws_iam_policy.argo_artifact_read_write_policy.arn
}

output "argo_db_password_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret storing the Argo DB password."
  value       = aws_secretsmanager_secret.argo_password.arn
}

output "argo_k8s_secret_name" {
  description = "The name of the Kubernetes secret containing the Auth0 client secret."
  value       = kubernetes_secret.argo_server_sso.metadata[0].name
}

output "argo_artifact_service_account_name" {
  description = "Kubernetes secret containing Argo artifact user credentials."
  value       = local.service_account_name_argo
}
