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

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID value"
  type        = string
}

variable "private_subnets_ids" {
  description = "List of private subnets ID"
  type        = list(string)
}

variable "eks_oidc_provider_arn" {
  description = "The OIDC issuer ARN for the EKS cluster"
  type        = string
}

variable "efs_backup_enabled" {
  description = "Enable EFS backup policy"
  type        = bool
  default     = false
}
