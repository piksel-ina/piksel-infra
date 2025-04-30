aws_region          = "ap-southeast-3"
project             = "piksel"
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
allowed_cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
common_tags = {
  Owner = "DevOps-Team"
}

# Explicitly define S3 settings for dev (matches defaults)
s3_kms_key_deletion_window_in_days = 7
s3_log_bucket_force_destroy        = true
s3_log_retention_days              = 90
# s3_data_raw_transition_days         = 30
s3_notebook_outputs_expiration_days = 30

# CloudFront domain configuration for dev
use_custom_domain      = false # Set to true when have a domain
domain_name            = ""    # Set to domain when ready, e.g., "dev-web.office-domain.com"
create_acm_certificate = false # Set to true when you want Terraform to create the certificate


# RDS - ODC Index Database Specifics for Dev
odc_db_instance_class          = "db.t3.large"
odc_db_allocated_storage       = 20
odc_db_max_allocated_storage   = 100 # Example limit for dev
odc_db_engine_version          = "17.2"
odc_db_backup_retention_period = 7
odc_db_multi_az                = true
odc_db_deletion_protection     = false              # Dev setting
odc_db_skip_final_snapshot     = true               # Dev setting
odc_db_name                    = "odc_index_dev_db" # Environment-specific DB name
odc_db_master_username         = "odc_master_dev"   # Environment-specific username
