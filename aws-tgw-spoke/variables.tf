# --- Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the resolver rule"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnets"
  type        = list(string)
}

variable "vpc_cidr_shared" {
  description = "CIDR block for the hub VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_vpc_route_table_id" {
  description = "Route table ID for this spoke VPC"
  type        = list(string)
}

variable "transit_gateway_id" {
  description = "ID of the shared Transit Gateway from hub account"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
