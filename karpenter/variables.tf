variable "cluster_name" {
  description = "Name of EKS Cluster"
}

variable "oidc_provider_arn" {
  description = "value"
}

variable "cluster_endpoint" {
  description = "value"
}

variable "public_repository_username" {
  description = "Repository username generated from token"
}

variable "public_repository_passowrd" {
  description = "Repository password generated from token"
}

variable "default_tags" {
  description = "value"
  default     = {}
}
