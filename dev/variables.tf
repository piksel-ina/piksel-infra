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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
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

variable "s3_data_raw_transition_days" {
  description = "Number of days before transitioning raw data to IA."
  type        = number
  default     = 30
}

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
