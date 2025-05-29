output "service_account_name" {
  value = kubernetes_service_account.external_dns.metadata[0].name
}

output "service_account_namespace" {
  value = kubernetes_service_account.external_dns.metadata[0].namespace
}

output "helm_release_status" {
  value = helm_release.external_dns.status
}
