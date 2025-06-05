variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
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

variable "public_hosted_zone_id" {
  description = "The ID of the public hosted zone"
  type        = string
}

variable "internal_buckets" {
  description = "List of internal S3 bucket names"
  type        = list(string)
  default     = []
}

variable "read_external_buckets" {
  description = "List of external S3 bucket names"
  type        = list(string)
  default     = []
}