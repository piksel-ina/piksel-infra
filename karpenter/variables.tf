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

variable "default_nodepool_ami_alias" {
  description = "AMI alias for default node pools"
  type        = string
  default     = "al2023@v20250505"
}

variable "gpu_nodepool_ami" {
  description = "AMI for GPU node pools"
  type        = string
  default     = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
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

variable "cross_account_ecr_role_arn" {
  description = "Cross Account ECR Role ARN"
  type        = string
  default     = "arn:aws:iam::686410905891:role/piksel-eks-ecr-access"
}
