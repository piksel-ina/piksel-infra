variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-3"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ARC resources"
  type        = string
  default     = "arc-runners"
}

variable "github_org" {
  description = "GitHub organization URL component"
  type        = string
  default     = "piksel-ina"
}

variable "github_app_id" {
  description = "GitHub App Client ID (supports both App ID and Client ID)"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App Private Key (PEM contents)"
  type        = string
  sensitive   = true
}

variable "runner_name" {
  description = "Runner scale set name (used as runner group label in workflows)"
  type        = string
  default     = "piksel-staging-runners"
}

variable "min_runners" {
  description = "Minimum number of idle runners"
  type        = number
  default     = 0
}

variable "max_runners" {
  description = "Maximum number of runners"
  type        = number
  default     = 5
}

variable "controller_chart_version" {
  description = "ARC controller Helm chart version"
  type        = string
  default     = "0.14.1"
}

variable "runner_chart_version" {
  description = "ARC runner scale set Helm chart version"
  type        = string
  default     = "0.14.1"
}

variable "tf_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  type        = string
}

variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}
