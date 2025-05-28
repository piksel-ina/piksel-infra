output "addon_externaldns" {
  description = "The addon module outputs"
  value       = module.external_dns_helm.addon
}

output "addon_irsa_externaldns" {
  description = "The addon IRSA module outputs"
  value       = module.external_dns_helm.addon_irsa
}
