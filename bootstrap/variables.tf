variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "Piksel"
}

variable "aws_region" {
  description = "AWS region for the Terraform state bucket"
  type        = string
  default     = "ap-southeast-3"
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "state_retention_days" {
  description = "Days to retain non-current state file versions before cleanup"
  type        = number
  default     = 90
}
