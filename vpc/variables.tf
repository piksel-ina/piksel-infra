# --- VPC Configuration Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use for subnets"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "Number of AZs must be between 1 and 3."
  }
}

variable "public_subnet_bits" {
  description = "Number of bits to allocate for public subnet CIDR"
  type        = number
  default     = 8
  validation {
    condition     = var.public_subnet_bits >= 1 && var.public_subnet_bits <= 8
    error_message = "Public subnet bits must be between 1 and 8."
  }
}

variable "private_subnet_bits" {
  description = "Number of bits to allocate for private subnet CIDR"
  type        = number
  default     = 6
  validation {
    condition     = var.private_subnet_bits >= 1 && var.private_subnet_bits <= 8
    error_message = "Private subnet bits must be between 1 and 8."
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
  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 3650
    error_message = "Retention days must be between 1 and 3650 (10 years)."
  }
}

# --- EKS Cluster Configuration ---
variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
  default     = "piksel-eks-cluster"
}

# --- Default Tags ---
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
