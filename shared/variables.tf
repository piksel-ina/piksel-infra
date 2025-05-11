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
  description = "Environment name (should be 'Shared' for this directory)"
  type        = string
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


#########################################################
# ECR Variables
#########################################################

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_max_tagged_images" {
  description = "Maximum number of tagged images to keep"
  type        = number
  default     = 5
}

variable "ecr_untagged_image_retention_days" {
  description = "Days to keep untagged images before expiration"
  type        = number
  default     = 7
}


#########################################################
# DNS Variables
#########################################################

variable "public_domain_name" {
  description = "List of public domains to create"
  type        = string
  default     = "piksel.big.go.id"
}

variable "internal_domains" {
  description = "Map of internal domain names for private hosted zones"
  type        = map(string)
  default = {
    dev     = "dev.piksel.internal"
    staging = "staging.piksel.internal"
    prod    = "prod.piksel.internal"
  }
}

variable "public_dns_records" {
  description = "List of DNS records to create in the public hosted zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = [] # Empty default so it doesn't create any records if not specified
}

variable "resolver_rule_domain_name" {
  description = "The domain name for which the central FORWARD resolver rule will apply (e.g., company.internal). This domain (and its subdomains) will be resolvable by spoke VPCs."
  type        = string
}

variable "spoke_vpc_cidrs" {
  description = "List of CIDR blocks for spoke VPCs that need to query the inbound resolver"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
