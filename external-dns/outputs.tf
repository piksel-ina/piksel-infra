# --- Outputs for reference ---
output "external_dns_iam_role_arn" {
  description = "ARN of the IAM role created for External DNS"
  value       = aws_iam_role.external_dns.arn
}

output "external_dns_namespace" {
  description = "Namespace where External DNS is deployed"
  value       = kubernetes_namespace.external_dns.metadata[0].name
}

output "external_dns_service_account_name" {
  description = "Name of the service account used by External DNS (managed by Helm)"
  value       = "external-dns"
}

output "external_dns_helm_release_name" {
  description = "Name of the Helm release for External DNS"
  value       = helm_release.external_dns.name
}

output "external_dns_helm_release_namespace" {
  description = "Namespace of the Helm release for External DNS"
  value       = helm_release.external_dns.namespace
}

output "external_dns_helm_release_status" {
  description = "Status of the Helm release for External DNS"
  value       = helm_release.external_dns.status
}

output "external_dns_helm_chart_version" {
  description = "Version of the External DNS Helm chart deployed"
  value       = helm_release.external_dns.version
}
