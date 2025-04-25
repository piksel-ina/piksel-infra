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

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.79   |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.95.0  |

## Modules

| Name                                                                       | Source                                               | Version |
| -------------------------------------------------------------------------- | ---------------------------------------------------- | ------- |
| <a name="module_vpc"></a> [vpc](#module_vpc)                               | terraform-aws-modules/vpc/aws                        | 5.21.0  |
| <a name="module_vpc_endpoints"></a> [vpc_endpoints](#module_vpc_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.21.0  |

## Resources

| Name                                                                                                                                             | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                             | resource    |
| [aws_security_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                        | resource    |
| [aws_security_group.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                     | resource    |
| [aws_security_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                      | resource    |
| [aws_security_group_rule.alb_http_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)      | resource    |
| [aws_security_group_rule.alb_https_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)     | resource    |
| [aws_security_group_rule.alb_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)          | resource    |
| [aws_security_group_rule.cluster_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)       | resource    |
| [aws_security_group_rule.cluster_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)      | resource    |
| [aws_security_group_rule.database_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)      | resource    |
| [aws_security_group_rule.nodes_cluster_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource    |
| [aws_security_group_rule.nodes_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)        | resource    |
| [aws_security_group_rule.nodes_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)        | resource    |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones)            | data source |

## Inputs

| Name                                                                                       | Description                                       | Type           | Default            | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------- | -------------- | ------------------ | :------: |
| <a name="input_allowed_cidr_blocks"></a> [allowed_cidr_blocks](#input_allowed_cidr_blocks) | List of CIDR blocks allowed to access the ALB     | `list(string)` | n/a                |   yes    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                            | AWS region to deploy resources                    | `string`       | `"ap-southeast-3"` |    no    |
| <a name="input_common_tags"></a> [common_tags](#input_common_tags)                         | Common tags to apply to all resources             | `map(string)`  | `{}`               |    no    |
| <a name="input_environment"></a> [environment](#input_environment)                         | Environment name                                  | `string`       | n/a                |   yes    |
| <a name="input_project"></a> [project](#input_project)                                     | Project name used for resource naming and tagging | `string`       | `"piksel"`         |    no    |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr)                                  | CIDR block for the VPC                            | `string`       | `"10.0.0.0/16"`    |    no    |

## Outputs

| Name                                                                                      | Description                                 |
| ----------------------------------------------------------------------------------------- | ------------------------------------------- |
| <a name="output_database_subnets"></a> [database_subnets](#output_database_subnets)       | List of IDs of database subnets             |
| <a name="output_private_subnets"></a> [private_subnets](#output_private_subnets)          | List of IDs of private subnets              |
| <a name="output_public_subnets"></a> [public_subnets](#output_public_subnets)             | List of IDs of public subnets               |
| <a name="output_security_group_ids"></a> [security_group_ids](#output_security_group_ids) | Security group IDs for different components |
| <a name="output_vpc_endpoints"></a> [vpc_endpoints](#output_vpc_endpoints)                | VPC Endpoint IDs                            |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                     | The ID of the VPC                           |

<!-- END_TF_DOCS -->
