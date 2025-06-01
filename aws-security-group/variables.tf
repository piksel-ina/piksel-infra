# --- Variables ---
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the security group"
  type        = string
}

variable "vpc_cidr_shared" {
  description = "CIDR block for the hub VPCs"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the deployment vpc"
  type        = string
}
