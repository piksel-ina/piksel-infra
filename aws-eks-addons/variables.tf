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

variable "zone_ids" {
  description = "List of Route53 hosted zone IDs ExternalDNS is allowed to manage."
  type        = list(string)
}

variable "aws_partition" {
  description = "The AWS partition" // usually 'aws', but might be 'aws-idn' in the future, like china and us: 'aws-cn' or 'aws-us-gov'
  type        = string
  default     = "aws"
}
