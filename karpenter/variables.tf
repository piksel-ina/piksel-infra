variable "cluster_name" {
  description = "Name of EKS Cluster"
}

variable "oidc_provider_arn" {
  description = "value"
}

variable "cluster_endpoint" {
  description = "value"
}

variable "default_tags" {
  description = "value"
  default     = {}
}

variable "default_nodepool_node_limit" {
  description = "Default node limit for node pools"
  type        = number
  default     = 10000
}

variable "gpu_nodepool_node_limit" {
  description = "Default GPU node limit for GPU node pools"
  type        = number
  default     = 20
}
