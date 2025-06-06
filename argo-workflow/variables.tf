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

variable "eks_oidc_provider_arn" {
  description = "The OIDC issuer ARN for the EKS cluster"
  type        = string
}

variable "max_session_duration" {
  type        = number
  description = "The maximum session duration for the role"
  default     = 10800
}

variable "jupyterhub_secret" {
  description = "Secret for JupyterHub"
  type        = string
}

variable "grafana_secret" {
  description = "Secret for Grafana"
  type        = string
}

variable "stacread_secret" {
  description = "Secret for STAC read-only access"
  type        = string
}

variable "stac_secret" {
  description = "Secret for STAC write access"
  type        = string
}

variable "odcread_secret" {
  description = "Secret for ODC read-only access"
  type        = string
}

variable "odc_secret" {
  description = "Secret for ODC write access"
  type        = string
}
