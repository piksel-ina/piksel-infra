variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
  default     = "piksel-eks-cluster"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "jhub_subdomain" {
  description = "Subdomain for JupyterHub"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "The OIDC issuer ARN for the EKS cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  type        = string
}

variable "auth0_tenant" {
  type        = string
  description = "The Auth0 tenant URL"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}
