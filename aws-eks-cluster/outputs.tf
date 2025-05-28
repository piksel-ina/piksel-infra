# --- Eks Cluster Outputs ---
output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster Certificate Authority Data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_provider_arn" {
  description = "EKS Cluster OIDC Provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "EKS Cluster OIDC Issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "EKS Cluster TLS Certificate SHA1 Fingerprint"
  value       = module.eks.cluster_tls_certificate_sha1_fingerprint
}
