# --- Common Variables ---
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

# --- Hostname Variables ---

variable "domain_name" {
  type    = string
  default = "piksel.big.go.id"
}

variable "subdomain_name" {
  type    = string
  default = "app.piksel.big.go.id"
}

variable "private_domain_name_hub" {
  type    = string
  default = "piksel.internal"
}

variable "private_domain_name_dev" {
  type    = string
  default = "dev.piksel.internal"
}

variable "private_domain_name_prod" {
  type    = string
  default = "prod.piksel.internal"
}

variable "vpc_id_shared" {
  type = string
}

# --- Records Variables ---
variable "enable_records_public" {
  description = "Enable public DNS records for the main public zone"
  type        = bool
  default     = false
}

variable "enable_records_subdomain" {
  description = "Enable public DNS records for the app subdomain"
  type        = bool
  default     = false
}

variable "enable_records_private_dev" {
  description = "Enable private DNS records for the dev environment"
  type        = bool
  default     = false
}

variable "enable_records_private_prod" {
  description = "Enable private DNS records for the dev environment"
  type        = bool
  default     = false
}

# --- Inbound and Outbound Rules Variables ---
variable "create_inbound_resolver_endpoint" {
  description = "Create an inbound resolver endpoint"
  type        = bool
  default     = true
}

variable "create_outbound_resolver_endpoint" {
  description = "Create an outbound resolver endpoint"
  type        = bool
  default     = false
}

variable "vpc_cidr_block_shared" {
  description = "CIDR block of the shared VPC"
  type        = string
}

variable "spoke_vpc_cidrs" {
  description = "values of spoke VPC CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "values of private subnets"
  type        = list(string)
}

variable "aws_account_ids" {
  description = "values of AWS account IDs"
  type        = list(string)
  default     = []
}

variable "vpc_id_dev" {
  description = "values of VPC ID for dev environment"
  type        = string
}
