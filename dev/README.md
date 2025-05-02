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


### Relational Database Service (RDS)

- **Modular Instances:** Utilizes the `terraform-aws-modules/rds/aws` module for consistent and maintainable deployment of RDS instances across environments.
- **IaC & GitOps Management:** All RDS resources (instances, subnet groups, parameter/option groups, security groups, secrets) are strictly defined in Terraform and managed via GitOps workflows for traceability and controlled changes.
- **Clear Separation:** Instances are segregated by environment (`dev`, `staging`, `prod`) and purpose (e.g., `odc-index`, `user-management`) using a consistent naming convention (`piksel-<environment>-<purpose>-rds`).
- **Standardized Tagging:** Mandatory tags (`Project`, `Environment`, `Purpose`, `ManagedBy`, `Owner`) are applied to all RDS instances and associated resources for identification, automation, and cost allocation.
- **Security by Default:**
  - **Encryption at Rest:** Server-Side Encryption is enabled using the default AWS-managed KMS key (`aws/rds`).
  - **Encryption in Transit:** SSL/TLS connections are enforced via custom RDS parameter group settings (`rds.force_ssl=1`).
  - **Network Isolation:** Instances are deployed in private database subnets with public accessibility disabled. Access is strictly controlled via VPC Security Groups.
  - **Secure Authentication:** IAM Database Authentication is enabled and preferred for application access. Master user credentials are automatically generated and stored securely in AWS Secrets Manager.
  - **Automated Backups:** Automated backups with Point-in-Time Recovery (PITR) are enabled, with configurable retention periods per environment.
- **High Availability Option:** Multi-AZ deployments are configurable via variables (e.g., `var.odc_db_multi_az`) for enhanced availability, recommended for staging and production.
- **Performance & Scalability:** Utilizes `gp3` storage for flexible performance tuning (IOPS/throughput independent of size). Instance class, storage allocation, and max allocated storage (autoscaling) are configurable per environment via variables.
- **Specific Engine Features:** Leverages PostgreSQL engine, with specific versions and necessary extensions (like PostGIS for ODC) managed via custom Option Groups and engine/family parameters.
- **Enhanced Monitoring:** Integrates Enhanced Monitoring, Performance Insights, and CloudWatch Logs (PostgreSQL engine logs, upgrade logs) for operational visibility.
- **Operational Safety:** Deletion protection and final snapshot configurations are available as variables, recommended to be enabled (`deletion_protection=true`, `skip_final_snapshot=false`) for staging and production environments.

- **Related Documents**:
  - [🔗 RDS Infrastructure Blueprint](https://github.com/piksel-ina/piksel-document/blob/main/architecture/database.md)
  - [🔗 Design vs Implementation](https://github.com/piksel-ina/piksel-document/blob/main/architecture/database.md#9-design-vs-implementation-odc-index-database---dev-environment)


## Backup and Recovery Strategy

This section briefly outlines the backup and recovery mechanisms implemented for key stateful services.

### Object Storage (S3)

- **Mechanism:** Primarily relies on **S3 Versioning** enabled on the `data` and `notebooks` buckets.
- **Protection:** Protects against accidental object deletion or overwrites within the bucket.
- **Recovery:** Allows restoration of previous object versions. Noncurrent versions are automatically deleted after `var.s3_noncurrent_version_retention_days`.
- **Web Bucket:** The `web` bucket does not have versioning enabled. Its content represents static website assets deployed via CI/CD. Recovery relies on redeployment through the CI/CD pipeline, with the source code versioned in Git.
- **Limitations:** Versioning occurs _within the same bucket and region_. It does not protect against accidental bucket deletion or regional failures. Cross-region replication is not used due to data residency requirements.

### Relational Database Service (RDS)

- **Mechanism:** Leverages **AWS automated backups**, including daily snapshots and transaction logs.
- **Protection:** Protects against data loss due to instance failure, data corruption, or accidental modification.
- **Recovery:** Supports **Point-in-Time Recovery (PITR)** up to any second within the `var.odc_db_backup_retention_period` (max 35 days) and restoration from specific snapshots.
- **Additional Safety:**
  - **Final Snapshot:** Configurable via `var.odc_db_skip_final_snapshot` (recommended: `false`) to retain a backup upon instance deletion.
  - **Deletion Protection:** Configurable via `var.odc_db_deletion_protection` (recommended: `true`) to prevent accidental instance deletion.
- **High Availability:** Multi-AZ deployments (controlled by `var.odc_db_multi_az`) provide high availability via a standby replica but are distinct from backups.
- **Compliance:** All RDS backups (automated snapshots, logs) are stored within the same AWS region as the instance.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 5.95 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.95.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_sg"></a> [alb\_sg](#module\_alb\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | 4.1.0 |
| <a name="module_eks_control_plane_sg"></a> [eks\_control\_plane\_sg](#module\_eks\_control\_plane\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_eks_nodes_sg"></a> [eks\_nodes\_sg](#module\_eks\_nodes\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_odc_rds"></a> [odc\_rds](#module\_odc\_rds) | terraform-aws-modules/rds/aws | 6.12.0 |
| <a name="module_rds_sg"></a> [rds\_sg](#module\_rds\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_s3_bucket_data_dev"></a> [s3\_bucket\_data\_dev](#module\_s3\_bucket\_data\_dev) | terraform-aws-modules/s3-bucket/aws | 4.7.0 |
| <a name="module_s3_bucket_notebooks_dev"></a> [s3\_bucket\_notebooks\_dev](#module\_s3\_bucket\_notebooks\_dev) | terraform-aws-modules/s3-bucket/aws | 4.7.0 |
| <a name="module_s3_bucket_web_dev"></a> [s3\_bucket\_web\_dev](#module\_s3\_bucket\_web\_dev) | terraform-aws-modules/s3-bucket/aws | 4.7.0 |
| <a name="module_s3_log_bucket"></a> [s3\_log\_bucket](#module\_s3\_log\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.7.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.21.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.21.0 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.web_cert](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.web_cert](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/acm_certificate_validation) | resource |
| [aws_kms_alias.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/kms_alias) | resource |
| [aws_kms_key.s3_key](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/kms_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.data_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.notebooks_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_log_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_tls_only_enforcement](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | List of CIDR blocks allowed to access the ALB | `list(string)` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"ap-southeast-3"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_acm_certificate"></a> [create\_acm\_certificate](#input\_create\_acm\_certificate) | Whether to create an ACM certificate for the custom domain | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Custom domain name for CloudFront distribution | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_odc_db_allocated_storage"></a> [odc\_db\_allocated\_storage](#input\_odc\_db\_allocated\_storage) | Initial allocated storage in GB for the ODC index RDS database. | `number` | `20` | no |
| <a name="input_odc_db_backup_retention_period"></a> [odc\_db\_backup\_retention\_period](#input\_odc\_db\_backup\_retention\_period) | Backup retention period in days for the ODC index RDS database. | `number` | `7` | no |
| <a name="input_odc_db_deletion_protection"></a> [odc\_db\_deletion\_protection](#input\_odc\_db\_deletion\_protection) | If the ODC index DB instance should have deletion protection enabled. | `bool` | `false` | no |
| <a name="input_odc_db_engine_version"></a> [odc\_db\_engine\_version](#input\_odc\_db\_engine\_version) | PostgreSQL engine version for the ODC index RDS database. | `string` | `"17.2-R2"` | no |
| <a name="input_odc_db_instance_class"></a> [odc\_db\_instance\_class](#input\_odc\_db\_instance\_class) | Instance class for the ODC index RDS database. | `string` | `"db.t3.large"` | no |
| <a name="input_odc_db_master_username"></a> [odc\_db\_master\_username](#input\_odc\_db\_master\_username) | Master username for the ODC index RDS instance. | `string` | `"odc_master"` | no |
| <a name="input_odc_db_max_allocated_storage"></a> [odc\_db\_max\_allocated\_storage](#input\_odc\_db\_max\_allocated\_storage) | Maximum storage size in GB for autoscaling the ODC index RDS database. | `number` | `100` | no |
| <a name="input_odc_db_multi_az"></a> [odc\_db\_multi\_az](#input\_odc\_db\_multi\_az) | Specifies if the ODC index RDS instance is multi-AZ. | `bool` | `true` | no |
| <a name="input_odc_db_name"></a> [odc\_db\_name](#input\_odc\_db\_name) | The name of the database to create in the ODC index RDS instance. | `string` | `"odc_index_db"` | no |
| <a name="input_odc_db_skip_final_snapshot"></a> [odc\_db\_skip\_final\_snapshot](#input\_odc\_db\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the ODC index DB instance is deleted. | `bool` | `true` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name used for resource naming and tagging | `string` | `"piksel"` | no |
| <a name="input_s3_kms_key_deletion_window_in_days"></a> [s3\_kms\_key\_deletion\_window\_in\_days](#input\_s3\_kms\_key\_deletion\_window\_in\_days) | Number of days to retain the S3 KMS key after deletion. | `number` | `7` | no |
| <a name="input_s3_log_bucket_force_destroy"></a> [s3\_log\_bucket\_force\_destroy](#input\_s3\_log\_bucket\_force\_destroy) | Force destroy the S3 log bucket (useful for dev/testing, disable in prod). | `bool` | `true` | no |
| <a name="input_s3_log_retention_days"></a> [s3\_log\_retention\_days](#input\_s3\_log\_retention\_days) | Number of days to retain S3 access logs before deleting. | `number` | `90` | no |
| <a name="input_s3_noncurrent_version_retention_days"></a> [s3\_noncurrent\_version\_retention\_days](#input\_s3\_noncurrent\_version\_retention\_days) | Number of days to keep noncurrent S3 object versions before expiration. | `number` | `7` | no |
| <a name="input_s3_notebook_outputs_expiration_days"></a> [s3\_notebook\_outputs\_expiration\_days](#input\_s3\_notebook\_outputs\_expiration\_days) | Number of days before expiring notebook outputs. | `number` | `30` | no |
| <a name="input_use_custom_domain"></a> [use\_custom\_domain](#input\_use\_custom\_domain) | Whether to use a custom domain for CloudFront | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | The domain name of the CloudFront distribution |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | The ID of the CloudFront distribution |
| <a name="output_cloudfront_distribution_url"></a> [cloudfront\_distribution\_url](#output\_cloudfront\_distribution\_url) | The URL of the CloudFront distribution |
| <a name="output_custom_domain_url"></a> [custom\_domain\_url](#output\_custom\_domain\_url) | The custom domain URL (if configured) |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | List of IDs of database subnets |
| <a name="output_odc_rds_instance_address"></a> [odc\_rds\_instance\_address](#output\_odc\_rds\_instance\_address) | The address of the ODC index RDS instance. |
| <a name="output_odc_rds_instance_arn"></a> [odc\_rds\_instance\_arn](#output\_odc\_rds\_instance\_arn) | The ARN of the ODC index RDS instance. |
| <a name="output_odc_rds_instance_endpoint"></a> [odc\_rds\_instance\_endpoint](#output\_odc\_rds\_instance\_endpoint) | The connection endpoint for the ODC index RDS instance. |
| <a name="output_odc_rds_instance_id"></a> [odc\_rds\_instance\_id](#output\_odc\_rds\_instance\_id) | The ID of the ODC index RDS instance. |
| <a name="output_odc_rds_instance_port"></a> [odc\_rds\_instance\_port](#output\_odc\_rds\_instance\_port) | The port the ODC index RDS instance is listening on. |
| <a name="output_odc_rds_master_user_secret_arn"></a> [odc\_rds\_master\_user\_secret\_arn](#output\_odc\_rds\_master\_user\_secret\_arn) | ARN of the Secrets Manager secret storing the master credentials for the ODC index RDS. |
| <a name="output_odc_rds_security_group_id"></a> [odc\_rds\_security\_group\_id](#output\_odc\_rds\_security\_group\_id) | The ID of the security group attached to the ODC index RDS instance. |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_s3_bucket_data_dev_arn"></a> [s3\_bucket\_data\_dev\_arn](#output\_s3\_bucket\_data\_dev\_arn) | ARN of the S3 data bucket for the dev environment |
| <a name="output_s3_bucket_data_dev_id"></a> [s3\_bucket\_data\_dev\_id](#output\_s3\_bucket\_data\_dev\_id) | ID (name) of the S3 data bucket for the dev environment |
| <a name="output_s3_bucket_notebooks_dev_arn"></a> [s3\_bucket\_notebooks\_dev\_arn](#output\_s3\_bucket\_notebooks\_dev\_arn) | ARN of the S3 notebooks bucket for the dev environment |
| <a name="output_s3_bucket_notebooks_dev_id"></a> [s3\_bucket\_notebooks\_dev\_id](#output\_s3\_bucket\_notebooks\_dev\_id) | ID (name) of the S3 notebooks bucket for the dev environment |
| <a name="output_s3_bucket_web_dev_arn"></a> [s3\_bucket\_web\_dev\_arn](#output\_s3\_bucket\_web\_dev\_arn) | ARN of the S3 web bucket for the dev environment |
| <a name="output_s3_bucket_web_dev_id"></a> [s3\_bucket\_web\_dev\_id](#output\_s3\_bucket\_web\_dev\_id) | ID (name) of the S3 web bucket for the dev environment |
| <a name="output_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#output\_s3\_kms\_key\_arn) | ARN of the KMS key used for S3 encryption |
| <a name="output_s3_log_bucket_id"></a> [s3\_log\_bucket\_id](#output\_s3\_log\_bucket\_id) | ID (name) of the S3 bucket used for access logging |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs for different components |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | VPC Endpoint IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
