variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "private_subnets_ids" {
  description = "List of private subnets ID"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
  default     = "piksel-eks-cluster"
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "db_instance_class" {
  description = "Database instance class (e.g., db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.", var.db_instance_class))
    error_message = "Database instance class must start with 'db.'"
  }
}

variable "db_allocated_storage" {
  description = "The allocated storage in gibibytes for the RDS instance"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GiB."
  }
}

variable "psql_family" {
  description = "Postrgress Database family"
  type        = string
  default     = "postgres16"
}

variable "psql_major_engine_version" {
  description = "Postrgress Database engine version"
  type        = string
  default     = "16"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "db_multi_az" {
  description = "Database multi availability zone deployment"
  type        = bool
}

variable "is_changes_applied_immediately" {
  description = "Apply RDS Changes Immediately instead during maintenance window"
  type        = bool
  default     = true
}

# --- Security Group Variables ---
variable "vpc_id" {
  description = "The ID of the VPC to associate with the security group"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the deployment vpc"
  type        = string
}
