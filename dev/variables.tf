# This file contains the variable definitions for the Piksel infrastructure

# Common variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-3"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "piksel"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["test", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be test, dev, staging, or prod."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Security Group variables
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
}

# S3 Specific Variables
variable "s3_kms_key_deletion_window_in_days" {
  description = "Number of days to retain the S3 KMS key after deletion."
  type        = number
  default     = 7 # Use 7 for dev/staging, 30 for prod
}

variable "s3_log_bucket_force_destroy" {
  description = "Force destroy the S3 log bucket (useful for dev/testing, disable in prod)."
  type        = bool
  default     = true # Set to false for staging/prod
}

variable "s3_log_retention_days" {
  description = "Number of days to retain S3 access logs before deleting."
  type        = number
  default     = 90
}

# variable "s3_data_raw_transition_days" {
#   description = "Number of days before transitioning raw data to IA."
#   type        = number
#   default     = 30
# }

variable "s3_notebook_outputs_expiration_days" {
  description = "Number of days before expiring notebook outputs."
  type        = number
  default     = 30
}

# Cloudfront Variables
variable "use_custom_domain" {
  description = "Whether to use a custom domain for CloudFront"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Custom domain name for CloudFront distribution"
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Whether to create an ACM certificate for the custom domain"
  type        = bool
  default     = false
}

# ------------------------------------------------------------------------------
# RDS - ODC Index Database Variables
# ------------------------------------------------------------------------------
variable "odc_db_instance_class" {
  description = "Instance class for the ODC index RDS database."
  type        = string
  default     = "db.t3.large" # Default based on blueprint v1.1
}

variable "odc_db_allocated_storage" {
  description = "Initial allocated storage in GB for the ODC index RDS database."
  type        = number
  default     = 20 # Default based on blueprint v1.1
}

variable "odc_db_max_allocated_storage" {
  description = "Maximum storage size in GB for autoscaling the ODC index RDS database."
  type        = number
  default     = 100 # Example limit, adjust as needed
}

variable "odc_db_engine_version" {
  description = "PostgreSQL engine version for the ODC index RDS database."
  type        = string
  default     = "17.2-R2" # Default based on blueprint v1.1
}

variable "odc_db_backup_retention_period" {
  description = "Backup retention period in days for the ODC index RDS database."
  type        = number
  default     = 7 # Default based on blueprint v1.1 for dev
}

variable "odc_db_multi_az" {
  description = "Specifies if the ODC index RDS instance is multi-AZ."
  type        = bool
  default     = true # Default based on blueprint v1.1
}

variable "odc_db_deletion_protection" {
  description = "If the ODC index DB instance should have deletion protection enabled."
  type        = bool
  default     = false # Typically false for dev, true for prod
}

variable "odc_db_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the ODC index DB instance is deleted."
  type        = bool
  default     = true # Typically true for dev, false for prod
}

variable "odc_db_name" {
  description = "The name of the database to create in the ODC index RDS instance."
  type        = string
  default     = "odc_index_db" # Example name
}

variable "odc_db_master_username" {
  description = "Master username for the ODC index RDS instance."
  type        = string
  default     = "odc_master" # Example username, DO NOT USE 'user', 'admin', 'postgres' etc.
}
