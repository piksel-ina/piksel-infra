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

variable "lifecycle_expiration_days" {
  description = "Number of days before objects expire. Override per environment (e.g. staging=90)"
  type        = number
  default     = 365
}
