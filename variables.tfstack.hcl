# --- Common Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
  default     = "Piksel"
}

variable "environment" {
  description = "The environment of the deployment"
  type        = string
}

variable "regions" {
  type = set(string)
}


variable "default_tags" {
  description = "A map of default tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}

# --- AWS OIDC Variables ---
variable "aws_token" {
  type      = string
  ephemeral = true
}

variable "aws_role" {
  type = string
}
