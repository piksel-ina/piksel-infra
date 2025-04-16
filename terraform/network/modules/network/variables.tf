variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_app_subnets" {
  description = "Map of private application subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_data_subnets" {
  description = "Map of private data subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "cluster_name" {
  description = "Name of the EKS cluster if applicable (for subnet tagging)"
  type        = string
  default     = ""
}

variable "azs_to_use" {
  description = "List of availability zones to actually use (determines where NAT Gateways are created)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway(s)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost saving for dev)"
  type        = bool
  default     = false
}
