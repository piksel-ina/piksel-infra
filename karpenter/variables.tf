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
  default     = "AWS"
}

variable "public_repository_password" {
  description = "Repository password generated from token"
  default     = null
}

variable "default_tags" {
  description = "value"
  default     = {}
}
