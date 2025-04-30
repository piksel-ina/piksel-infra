# Development Environment Infrastructure

## Overview

This repository contains the Terraform configuration for provisioning the core AWS networking infrastructure for the **Piksel** project's **development** environment.

## File Structure

This Terraform configuration is organized into the following files:

| File              | Description                                                                                                                                                                                                                      |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `main.tf`         | Defines the core infrastructure resources                                                                                                                                                                                        |
| `variables.tf`    | Declares all input variables used in the configuration, including descriptions, types, default values, and validation rules.                                                                                                     |
| `outputs.tf`      | Defines the outputs that will be displayed after a successful `terraform apply`. These outputs expose important identifiers (like VPC ID, subnet IDs, SG IDs) for use in other configurations or for reference.                  |
| `providers.tf`    | Specifies the required Terraform version and the AWS provider configuration, including version constraints.                                                                                                                      |
| `dev.auto.tfvars` | Contains specific variable values for the 'dev' environment. Terraform automatically loads `*.auto.tfvars` files. Would typically create similar files for other environments (e.g., `staging.auto.tfvars`, `prod.auto.tfvars`). |
| `README.md`       | This file, providing documentation on the configuration, setup, and usage.                                                                                                                                                       |

## Key Design Decisions

### Network

- **Modular VPC:** Uses the battle-tested `terraform-aws-modules/vpc/aws` module for VPC creation, promoting reuse and maintainability.
- **Environment-Specific NAT:** Deploys a single NAT Gateway in non-production environments to save costs, while using one NAT Gateway per AZ in production for high availability, as recommended.
- **Clear Subnet Strategy:** Segregates resources into public, private application, and private data subnets for better security and organization.
- **VPC Endpoints:** Includes endpoints for S3 and ECR to keep traffic within the AWS network, improving security and potentially reducing data transfer costs.
- **Specific Security Groups:** Defines dedicated security groups for different components (EKS, ALB, DB) following the principle of least privilege.
- **EKS Tagging:** Applies necessary tags (`kubernetes.io/role/...`) to subnets and security groups for EKS compatibility.

- **Related Documents**:
  - [🔗 Network Design in Detail](https://github.com/piksel-ina/piksel-document/blob/main/architecture/network.md)
  - [🔗 Design vs implementation](https://github.com/piksel-ina/piksel-document/blob/main/architecture/network.md#network-design-vs-implementation)

### Object Storage (S3)

- **Modular Buckets:** Utilizes the `terraform-aws-modules/s3-bucket/aws` module for consistency and maintainability across all S3 buckets.
- **IaC & GitOps Management:** All S3 resources are strictly defined in Terraform and managed via GitOps workflows, ensuring traceability and controlled changes.
- **Clear Separation:** Buckets are segregated by environment (`dev`, `staging`, `prod`) and purpose (`data`, `notebooks`, `web`) using a consistent naming convention (`Piksel-<environment>-<purpose>`).
- **Standardized Tagging:** Mandatory tags (`Project`, `Environment`, `Purpose`, `ManagedBy`, `Owner`) are applied to all buckets for identification and cost allocation.
- **Security by Default:**
  - **Encryption:** Server-Side Encryption with AWS KMS (SSE-KMS) is enforced on all buckets.
  - **Block Public Access:** Enabled by default for all buckets. `web` buckets are accessed securely via CloudFront OAI/OAC, not direct public access.
  - **Versioning:** Enabled on `data` and `notebooks` buckets to protect against accidental deletion or overwrites. Disabled on `web` buckets where content is overwritten by CI/CD.
  - **Access Logging:** Centralized S3 server access logging is configured for all buckets, targeting a dedicated logging bucket.
  - **TLS Enforcement:** Secure transport (HTTPS) is enforced via bucket policies.
- **VPC Endpoint Integration:** S3 VPC endpoints are utilized within each environment's VPC to allow private, secure access from internal resources like EKS pods and EC2 instances.
- **Cost Optimization:**
  - **Storage Classes:** Appropriate storage classes (e.g., `INTELLIGENT_TIERING` for `data`, `STANDARD` for others) are selected based on access patterns.
  - **Lifecycle Rules:** Implemented to transition or expire objects automatically (e.g., moving raw data to Infrequent Access, deleting temporary outputs).
- **Defined Access Patterns:** Access is granted based on the principle of least privilege using IAM Roles, IRSA for EKS pods, CI/CD pipeline roles, and CloudFront Origin Access for `web` buckets.

- **Related Documents**:
  - [🔗 S3 Infrastructure Blueprint](https://github.com/piksel-ina/piksel-document/blob/main/architecture/object-storage.md)
  - [🔗 Design vs Implementation](https://github.com/piksel-ina/piksel-document/blob/main/architecture/object-storage.md#design-vs-implementation)

---

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | = 5.95    |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.95.0  |

## Modules

| Name                                                                                                     | Source                                               | Version |
| -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ------- |
| <a name="module_alb_sg"></a> [alb_sg](#module_alb_sg)                                                    | terraform-aws-modules/security-group/aws             | 5.3.0   |
| <a name="module_cloudfront"></a> [cloudfront](#module_cloudfront)                                        | terraform-aws-modules/cloudfront/aws                 | 4.1.0   |
| <a name="module_eks_control_plane_sg"></a> [eks_control_plane_sg](#module_eks_control_plane_sg)          | terraform-aws-modules/security-group/aws             | 5.3.0   |
| <a name="module_eks_nodes_sg"></a> [eks_nodes_sg](#module_eks_nodes_sg)                                  | terraform-aws-modules/security-group/aws             | 5.3.0   |
| <a name="module_odc_rds"></a> [odc_rds](#module_odc_rds)                                                 | terraform-aws-modules/rds/aws                        | 6.12.0  |
| <a name="module_rds_sg"></a> [rds_sg](#module_rds_sg)                                                    | terraform-aws-modules/security-group/aws             | 5.3.0   |
| <a name="module_s3_bucket_data_dev"></a> [s3_bucket_data_dev](#module_s3_bucket_data_dev)                | terraform-aws-modules/s3-bucket/aws                  | 4.7.0   |
| <a name="module_s3_bucket_notebooks_dev"></a> [s3_bucket_notebooks_dev](#module_s3_bucket_notebooks_dev) | terraform-aws-modules/s3-bucket/aws                  | 4.7.0   |
| <a name="module_s3_bucket_web_dev"></a> [s3_bucket_web_dev](#module_s3_bucket_web_dev)                   | terraform-aws-modules/s3-bucket/aws                  | 4.7.0   |
| <a name="module_s3_log_bucket"></a> [s3_log_bucket](#module_s3_log_bucket)                               | terraform-aws-modules/s3-bucket/aws                  | 4.7.0   |
| <a name="module_vpc"></a> [vpc](#module_vpc)                                                             | terraform-aws-modules/vpc/aws                        | 5.21.0  |
| <a name="module_vpc_endpoints"></a> [vpc_endpoints](#module_vpc_endpoints)                               | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.21.0  |

## Resources

| Name                                                                                                                                                | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_acm_certificate.web_cert](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/acm_certificate)                           | resource    |
| [aws_acm_certificate_validation.web_cert](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/acm_certificate_validation)     | resource    |
| [aws_kms_alias.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/kms_alias)                                         | resource    |
| [aws_kms_key.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/kms_key)                                             | resource    |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/availability_zones)                 | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/caller_identity)                         | data source |
| [aws_iam_policy_document.data_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document)      | data source |
| [aws_iam_policy_document.notebooks_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_log_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document)    | data source |
| [aws_iam_policy_document.s3_tls_only_enforcement](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name                                                                                                                                       | Description                                                                                    | Type           | Default            | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- | -------------- | ------------------ | :------: |
| <a name="input_allowed_cidr_blocks"></a> [allowed_cidr_blocks](#input_allowed_cidr_blocks)                                                 | List of CIDR blocks allowed to access the ALB                                                  | `list(string)` | n/a                |   yes    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                                                                            | AWS region to deploy resources                                                                 | `string`       | `"ap-southeast-3"` |    no    |
| <a name="input_common_tags"></a> [common_tags](#input_common_tags)                                                                         | Common tags to apply to all resources                                                          | `map(string)`  | `{}`               |    no    |
| <a name="input_create_acm_certificate"></a> [create_acm_certificate](#input_create_acm_certificate)                                        | Whether to create an ACM certificate for the custom domain                                     | `bool`         | `false`            |    no    |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name)                                                                         | Custom domain name for CloudFront distribution                                                 | `string`       | `""`               |    no    |
| <a name="input_environment"></a> [environment](#input_environment)                                                                         | Environment name                                                                               | `string`       | n/a                |   yes    |
| <a name="input_odc_db_allocated_storage"></a> [odc_db_allocated_storage](#input_odc_db_allocated_storage)                                  | Initial allocated storage in GB for the ODC index RDS database.                                | `number`       | `20`               |    no    |
| <a name="input_odc_db_backup_retention_period"></a> [odc_db_backup_retention_period](#input_odc_db_backup_retention_period)                | Backup retention period in days for the ODC index RDS database.                                | `number`       | `7`                |    no    |
| <a name="input_odc_db_deletion_protection"></a> [odc_db_deletion_protection](#input_odc_db_deletion_protection)                            | If the ODC index DB instance should have deletion protection enabled.                          | `bool`         | `false`            |    no    |
| <a name="input_odc_db_engine_version"></a> [odc_db_engine_version](#input_odc_db_engine_version)                                           | PostgreSQL engine version for the ODC index RDS database.                                      | `string`       | `"17.2-R2"`        |    no    |
| <a name="input_odc_db_instance_class"></a> [odc_db_instance_class](#input_odc_db_instance_class)                                           | Instance class for the ODC index RDS database.                                                 | `string`       | `"db.t3.large"`    |    no    |
| <a name="input_odc_db_master_username"></a> [odc_db_master_username](#input_odc_db_master_username)                                        | Master username for the ODC index RDS instance.                                                | `string`       | `"odc_master"`     |    no    |
| <a name="input_odc_db_max_allocated_storage"></a> [odc_db_max_allocated_storage](#input_odc_db_max_allocated_storage)                      | Maximum storage size in GB for autoscaling the ODC index RDS database.                         | `number`       | `100`              |    no    |
| <a name="input_odc_db_multi_az"></a> [odc_db_multi_az](#input_odc_db_multi_az)                                                             | Specifies if the ODC index RDS instance is multi-AZ.                                           | `bool`         | `true`             |    no    |
| <a name="input_odc_db_name"></a> [odc_db_name](#input_odc_db_name)                                                                         | The name of the database to create in the ODC index RDS instance.                              | `string`       | `"odc_index_db"`   |    no    |
| <a name="input_odc_db_skip_final_snapshot"></a> [odc_db_skip_final_snapshot](#input_odc_db_skip_final_snapshot)                            | Determines whether a final DB snapshot is created before the ODC index DB instance is deleted. | `bool`         | `true`             |    no    |
| <a name="input_project"></a> [project](#input_project)                                                                                     | Project name used for resource naming and tagging                                              | `string`       | `"piksel"`         |    no    |
| <a name="input_s3_kms_key_deletion_window_in_days"></a> [s3_kms_key_deletion_window_in_days](#input_s3_kms_key_deletion_window_in_days)    | Number of days to retain the S3 KMS key after deletion.                                        | `number`       | `7`                |    no    |
| <a name="input_s3_log_bucket_force_destroy"></a> [s3_log_bucket_force_destroy](#input_s3_log_bucket_force_destroy)                         | Force destroy the S3 log bucket (useful for dev/testing, disable in prod).                     | `bool`         | `true`             |    no    |
| <a name="input_s3_log_retention_days"></a> [s3_log_retention_days](#input_s3_log_retention_days)                                           | Number of days to retain S3 access logs before deleting.                                       | `number`       | `90`               |    no    |
| <a name="input_s3_notebook_outputs_expiration_days"></a> [s3_notebook_outputs_expiration_days](#input_s3_notebook_outputs_expiration_days) | Number of days before expiring notebook outputs.                                               | `number`       | `30`               |    no    |
| <a name="input_use_custom_domain"></a> [use_custom_domain](#input_use_custom_domain)                                                       | Whether to use a custom domain for CloudFront                                                  | `bool`         | `false`            |    no    |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr)                                                                                  | CIDR block for the VPC                                                                         | `string`       | `"10.0.0.0/16"`    |    no    |

## Outputs

| Name                                                                                                                                         | Description                                                                             |
| -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront_distribution_domain_name](#output_cloudfront_distribution_domain_name) | The domain name of the CloudFront distribution                                          |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront_distribution_id](#output_cloudfront_distribution_id)                            | The ID of the CloudFront distribution                                                   |
| <a name="output_cloudfront_distribution_url"></a> [cloudfront_distribution_url](#output_cloudfront_distribution_url)                         | The URL of the CloudFront distribution                                                  |
| <a name="output_custom_domain_url"></a> [custom_domain_url](#output_custom_domain_url)                                                       | The custom domain URL (if configured)                                                   |
| <a name="output_database_subnets"></a> [database_subnets](#output_database_subnets)                                                          | List of IDs of database subnets                                                         |
| <a name="output_odc_rds_instance_address"></a> [odc_rds_instance_address](#output_odc_rds_instance_address)                                  | The address of the ODC index RDS instance.                                              |
| <a name="output_odc_rds_instance_arn"></a> [odc_rds_instance_arn](#output_odc_rds_instance_arn)                                              | The ARN of the ODC index RDS instance.                                                  |
| <a name="output_odc_rds_instance_endpoint"></a> [odc_rds_instance_endpoint](#output_odc_rds_instance_endpoint)                               | The connection endpoint for the ODC index RDS instance.                                 |
| <a name="output_odc_rds_instance_id"></a> [odc_rds_instance_id](#output_odc_rds_instance_id)                                                 | The ID of the ODC index RDS instance.                                                   |
| <a name="output_odc_rds_instance_port"></a> [odc_rds_instance_port](#output_odc_rds_instance_port)                                           | The port the ODC index RDS instance is listening on.                                    |
| <a name="output_odc_rds_master_user_secret_arn"></a> [odc_rds_master_user_secret_arn](#output_odc_rds_master_user_secret_arn)                | ARN of the Secrets Manager secret storing the master credentials for the ODC index RDS. |
| <a name="output_odc_rds_security_group_id"></a> [odc_rds_security_group_id](#output_odc_rds_security_group_id)                               | The ID of the security group attached to the ODC index RDS instance.                    |
| <a name="output_private_subnets"></a> [private_subnets](#output_private_subnets)                                                             | List of IDs of private subnets                                                          |
| <a name="output_public_subnets"></a> [public_subnets](#output_public_subnets)                                                                | List of IDs of public subnets                                                           |
| <a name="output_s3_bucket_data_dev_arn"></a> [s3_bucket_data_dev_arn](#output_s3_bucket_data_dev_arn)                                        | ARN of the S3 data bucket for the dev environment                                       |
| <a name="output_s3_bucket_data_dev_id"></a> [s3_bucket_data_dev_id](#output_s3_bucket_data_dev_id)                                           | ID (name) of the S3 data bucket for the dev environment                                 |
| <a name="output_s3_bucket_notebooks_dev_arn"></a> [s3_bucket_notebooks_dev_arn](#output_s3_bucket_notebooks_dev_arn)                         | ARN of the S3 notebooks bucket for the dev environment                                  |
| <a name="output_s3_bucket_notebooks_dev_id"></a> [s3_bucket_notebooks_dev_id](#output_s3_bucket_notebooks_dev_id)                            | ID (name) of the S3 notebooks bucket for the dev environment                            |
| <a name="output_s3_bucket_web_dev_arn"></a> [s3_bucket_web_dev_arn](#output_s3_bucket_web_dev_arn)                                           | ARN of the S3 web bucket for the dev environment                                        |
| <a name="output_s3_bucket_web_dev_id"></a> [s3_bucket_web_dev_id](#output_s3_bucket_web_dev_id)                                              | ID (name) of the S3 web bucket for the dev environment                                  |
| <a name="output_s3_kms_key_arn"></a> [s3_kms_key_arn](#output_s3_kms_key_arn)                                                                | ARN of the KMS key used for S3 encryption                                               |
| <a name="output_s3_log_bucket_id"></a> [s3_log_bucket_id](#output_s3_log_bucket_id)                                                          | ID (name) of the S3 bucket used for access logging                                      |
| <a name="output_security_group_ids"></a> [security_group_ids](#output_security_group_ids)                                                    | Security group IDs for different components                                             |
| <a name="output_vpc_endpoints"></a> [vpc_endpoints](#output_vpc_endpoints)                                                                   | VPC Endpoint IDs                                                                        |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                                                                        | The ID of the VPC                                                                       |

<!-- END_TF_DOCS -->
