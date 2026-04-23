# --- Common Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
  default     = "Piksel"
}

variable "environment" {
  description = "The environment of the deployment"
  type        = string
  default     = "Staging"
}

variable "aws_region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "ap-southeast-3"
}

variable "default_tags" {
  description = "A map of default tags to apply to all AWS resources"
  type        = map(string)
  default = {
    "ManagedBy"   = "Terraform"
    "Project"     = "Piksel"
    "Owner"       = "Piksel-Devops-Team"
    "Environment" = "Staging"
  }
}

# --- NAT Gateway Configuration ---
variable "single_nat_gateway" {
  description = "Enable a single NAT Gateway for all private subnets (cheaper, less availability)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Enable one NAT Gateway per Availability Zone (higher availability, higher cost)"
  type        = bool
  default     = false
}

# --- VPC Flow Logs Configuration ---
variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for monitoring network traffic"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention period for VPC Flow Logs in CloudWatch (in days)"
  type        = number
  default     = 90
}

# --- ARC Runner Variables ---
variable "arc_github_app_id" {
  description = "GitHub App Client ID for ARC authentication"
  type        = string
  sensitive   = true
}

variable "arc_github_app_installation_id" {
  description = "GitHub App Installation ID for ARC"
  type        = string
  sensitive   = true
}

variable "arc_github_app_private_key" {
  description = "GitHub App Private Key for ARC (PEM contents)"
  type        = string
  sensitive   = true
}

variable "pg_host" {
  description = "Override PostgreSQL host for the terraform provider. Use 'localhost' when tunnelling via port-forward"
  type        = string
  default     = ""
}

variable "pg_port" {
  description = "Override PostgreSQL port for the terraform provider. Use the local port when tunnelling via port-forward"
  type        = number
  default     = 5432
}
