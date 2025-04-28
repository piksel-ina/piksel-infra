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
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | 4.1.0 |
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
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group) | resource |
| [aws_security_group.database](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group) | resource |
| [aws_security_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group) | resource |
| [aws_security_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group) | resource |
| [aws_security_group_rule.alb_http_inbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.alb_https_inbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.alb_outbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster_inbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster_outbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.database_inbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.nodes_cluster_inbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.nodes_internal](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.nodes_outbound](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/security_group_rule) | resource |
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
| <a name="input_project"></a> [project](#input\_project) | Project name used for resource naming and tagging | `string` | `"piksel"` | no |
| <a name="input_s3_kms_key_deletion_window_in_days"></a> [s3\_kms\_key\_deletion\_window\_in\_days](#input\_s3\_kms\_key\_deletion\_window\_in\_days) | Number of days to retain the S3 KMS key after deletion. | `number` | `7` | no |
| <a name="input_s3_log_bucket_force_destroy"></a> [s3\_log\_bucket\_force\_destroy](#input\_s3\_log\_bucket\_force\_destroy) | Force destroy the S3 log bucket (useful for dev/testing, disable in prod). | `bool` | `true` | no |
| <a name="input_s3_log_retention_days"></a> [s3\_log\_retention\_days](#input\_s3\_log\_retention\_days) | Number of days to retain S3 access logs before deleting. | `number` | `90` | no |
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
