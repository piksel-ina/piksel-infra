variable "subdomains" {
  description = "List of domain filters for ExternalDNS"
  type        = list(string)
}

variable "externaldns_crossaccount_role_arn" {
  description = "The ARN of the cross-account IAM role in Route53 account"
  type        = string
}

variable "oidc_provider" {
  description = "EKS Cluster OIDC provider issuer "
}

variable "oidc_provider_arn" {
  description = "EKS Cluster OIDC provider arn "
}
