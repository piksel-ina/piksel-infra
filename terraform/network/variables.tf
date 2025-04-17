variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-3" # Jakarta

  validation {
    condition     = contains(["ap-southeast-3"], var.aws_region)
    error_message = "Currently, only ap-southeast-3 (Jakarta) region is supported."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR block must be a valid CIDR notation."
  }
}

variable "azs_to_use" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateways for private subnets"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  validation {
    condition     = alltrue([for subnet in values(var.public_subnets) : can(cidrnetmask(subnet.cidr_block))])
    error_message = "All public subnet CIDR blocks must be valid CIDR notations."
  }
}

variable "private_app_subnets" {
  description = "Map of private application subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  validation {
    condition     = alltrue([for subnet in values(var.private_app_subnets) : can(cidrnetmask(subnet.cidr_block))])
    error_message = "All private app subnet CIDR blocks must be valid CIDR notations."
  }
}

variable "private_data_subnets" {
  description = "Map of private data subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  validation {
    condition     = alltrue([for subnet in values(var.private_data_subnets) : can(cidrnetmask(subnet.cidr_block))])
    error_message = "All private data subnet CIDR blocks must be valid CIDR notations."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster, if any"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
