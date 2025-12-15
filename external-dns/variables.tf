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

variable "aws_partition" {
  description = "The AWS partition" // usually 'aws', but might be 'aws-idn' in the future, like china and us: 'aws-cn' or 'aws-us-gov'
  type        = string
  default     = "aws"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "default_tags" {
  description = "Default tags"
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}
