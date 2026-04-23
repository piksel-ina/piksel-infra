output "grafana_namespace" {
  description = "The Kubernetes namespace where monitoring resources are deployed."
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_iam_role_arn" {
  description = "The IAM role ARN used by Grafana for IRSA (CloudWatch access). Empty when Grafana is disabled."
  value       = var.enable_grafana ? aws_iam_role.grafana[0].arn : ""
}

output "grafana_cloudwatch_policy_arn" {
  description = "The IAM policy ARN attached to Grafana for CloudWatch access. Empty when Grafana is disabled."
  value       = var.enable_grafana ? aws_iam_policy.grafana_cloudwatch[0].arn : ""
}

output "grafana_admin_secret_name" {
  description = "The name of the Kubernetes secret storing the Grafana admin credentials. Empty when Grafana is disabled."
  value       = var.enable_grafana ? kubernetes_secret.grafana_admin_credentials[0].metadata[0].name : ""
}

output "grafana_values_secret_name" {
  description = "The name of the Kubernetes secret containing the Grafana Helm values. Empty when Grafana is disabled."
  value       = var.enable_grafana ? kubernetes_secret.grafana[0].metadata[0].name : ""
}

output "grafana_oauth_client_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret for the Grafana OAuth client/secret. Empty when Grafana is disabled."
  value       = var.enable_grafana ? data.aws_secretsmanager_secret_version.grafana_client_secret[0].arn : ""
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

output "stacread_k8s_secret_name" {
  description = "Kubernetes secret name for STAC read credentials."
  value       = kubernetes_secret.stacread_namespace_secret.metadata[0].name
}

# --- Terria Output ---
output "terria_bucket_name" {
  description = "The name of the S3 bucket for Terria."
  value       = aws_s3_bucket.terria_bucket.id
}

output "terria_bucket_arn" {
  description = "ARN of the S3 bucket for TerriaMap"
  value       = aws_s3_bucket.terria_bucket.arn
}


output "terria_iam_role_arn" {
  description = "ARN of the IAM role for TerriaMap service account (IRSA)"
  value       = aws_iam_role.terria_role.arn
}

output "terria_iam_role_name" {
  description = "Name of the IAM role for TerriaMap"
  value       = aws_iam_role.terria_role.name
}

output "terria_namespace" {
  description = "Kubernetes namespace for TerriaMap"
  value       = kubernetes_namespace.terria.metadata[0].name
}

output "terria_service_account_name" {
  description = "Name of the Kubernetes service account for TerriaMap"
  value       = kubernetes_service_account.terria.metadata[0].name
}

output "terria_configmap_name" {
  description = "Name of the ConfigMap containing TerriaMap configuration"
  value       = kubernetes_config_map.terria_config.metadata[0].name
}

# --- Flux outputs ---
# output "flux_namespace" {
#   description = "The namespace where Flux is deployed"
#   value       = kubernetes_namespace.flux_system.metadata[0].name
# }

# output "slack_webhook_secret_name" {
#   description = "Slack webhook secret name"
#   value       = kubernetes_secret.slack_webhook.metadata[0].name
# }

# output "slack_webhook_secret_arn" {
#   description = "The ARN of the AWS Secrets Manager secret for the Slack Webhook."
#   value       = data.aws_secretsmanager_secret_version.slack_webhook.arn
# }

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

output "argo_k8s_secret_name" {
  description = "The name of the Kubernetes secret containing the Auth0 client secret."
  value       = kubernetes_secret.argo_server_sso.metadata[0].name
}

output "argo_artifact_service_account_name" {
  description = "Kubernetes secret containing Argo artifact user credentials."
  value       = local.service_account_name_argo
}
