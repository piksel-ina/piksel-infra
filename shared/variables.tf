# Common variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  # Default can be set here or in tfvars
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  # Default can be set here or in tfvars
}

variable "environment" {
  description = "Environment name (should be 'shared' for this directory)"
  type        = string
  validation {
    # Adjust validation if needed, or rely on tfvars
    condition     = var.environment == "shared"
    error_message = "Environment must be shared for this configuration."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for the Shared VPC"
  type        = string
  # Default can be set here or in tfvars
}

variable "transit_gateway_amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session. Required if creating a new TGW."
  type        = number
  default     = 64512 # Example default private ASN
}

variable "tgw_ram_principals" {
  description = "List of AWS Account IDs or OU ARNs to share the TGW with."
  type        = list(string)
  default     = []
}
