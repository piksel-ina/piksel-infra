aws_region          = "ap-southeast-3"
project             = "piksel"
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
allowed_cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
common_tags = {
  Project     = "Piksel"
  Environment = "Dev"
  ManagedBy   = "Terraform"
  Owner       = "DevOps-Team"
}

# Explicitly define S3 settings for dev (matches defaults)
s3_kms_key_deletion_window_in_days  = 7
s3_log_bucket_force_destroy         = true
s3_log_retention_days               = 90
s3_data_raw_transition_days         = 30
s3_notebook_outputs_expiration_days = 30
