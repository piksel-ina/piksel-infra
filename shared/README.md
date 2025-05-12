# Piksel Shared Account

## Overview

This Terraform configuration defines and manages the infrastructure for the **Piksel Shared** AWS account in the target region (`ap-southeast-3`). This account serves as a central hub for shared services and connectivity across different Piksel environments (development, staging, production accounts).

The primary services initially intended for this shared account are:

- **AWS Elastic Container Registry (ECR):** To store and manage Docker container images centrally.
- **DNS Management (Route 53):** Potentially hosting shared private or public zones (though zone resources might be defined elsewhere).

This networking foundation ensures secure, scalable, and private communication for these services and facilitates connectivity with other VPCs within the Piksel organization.

## Design Decisions & Rationale

### Network

The networking design incorporates several key components and patterns:

1.  **Dedicated VPC:**

    - An isolated Virtual Private Cloud is created, configured via the `vpc_cidr` variable (`10.1.0.0/16`).
    - Provides a private network space within AWS dedicated to shared resources, enhancing security and organization.

2.  **Public and Private Subnets:**

    - The VPC is segmented into public and private subnets across multiple Availability Zones (AZs) for high availability. Subnet CIDRs are calculated based on the main VPC CIDR.
    - Standard security practice.
      - _Public Subnets_ host resources that need direct internet access (like NAT Gateways).
      - _Private Subnets_ host internal resources (like application servers, databases, and crucially, VPC endpoints) that should not be directly exposed to the internet. Resources in private subnets access the internet via NAT Gateways located in the public subnets.

3.  **Transit Gateway (TGW):**

    - A central AWS Transit Gateway is deployed, and the Shared VPC is attached to it using the private subnets.
    - **Why:**
      - **Scalable Connectivity:** Acts as a cloud router using a hub-and-spoke model. This simplifies connecting multiple VPCs (from other accounts like dev/prod) compared to complex VPC peering meshes.
      - **Centralized Routing:** Simplifies network administration and routing policies between connected networks.
      - **Future-Proofing:** Allows easy integration of future VPCs, Direct Connect gateways, or VPN connections.
      - **Private Subnet Attachment:** Routing traffic through private subnets ensures resources leverage VPC endpoints and internal routing before potentially going external.

4.  **VPC Endpoints:**
    - Interface VPC Endpoints are created within the private subnets for key AWS services (ECR API, ECR DKR, CloudWatch Logs, STS) and a Gateway Endpoint for S3.
    - **Why:**
      - **Private Connectivity:** Allows resources within the VPC (and potentially peered VPCs via TGW) to access these AWS services without traversing the public internet. This enhances security and can reduce data transfer costs.
      - **ECR Support:** Essential for allowing resources within this VPC (or connected VPCs) to securely pull/push images from/to the central ECR repositories using AWS PrivateLink.
      - **DNS Integration:** Endpoints with Private DNS enabled allow standard AWS service hostnames to resolve to private IP addresses within the VPC, ensuring seamless private access for applications.
      - **Dependency Services:** Endpoints for Logs, STS, and S3 are common dependencies for many AWS workflows and applications, ensuring they also benefit from private connectivity.

### Container Registry (ECR)

The Elastic Container Registry configuration includes the following design decisions:

1. **Private ECR Repository:**

   - Using private ECR repositories for secure storage of container images
   - Configured in the primary region (`ap-southeast-3`)
   - Centralized repository with consistent naming convention (`${project}-core`)

2. **Access Control:**

   - GitHub Actions access via OIDC provider for secure CI/CD integration
   - EKS access role for Kubernetes-based workloads to pull images
   - Fine-grained IAM policies for both push and pull operations

3. **Lifecycle Management:**

   - Automated cleanup of untagged images to reduce storage costs
   - Retention policies for tagged images to maintain important versions
   - Optimized for both storage efficiency and deployment availability

4. **Security Considerations:**
   - Repository policies restrict access to specific IAM roles
   - Private registry ensures images are not publicly accessible
   - Integration with AWS security services for image scanning and vulnerability detection

For complete details on the container registry architecture and configuration, please refer to our [Container Registry Design Document](https://github.com/piksel-ina/piksel-document/blob/main/architecture/container-registry.md).

## Cross-Account Connectivity

The Transit Gateway created here is intended to be shared with other Piksel AWS accounts using AWS Resource Access Manager (RAM).

- Sharing is enabled via the `ram_allow_external_principals = true` argument in the `module "tgw"` block.
- The specific AWS Account IDs authorized to attach to this TGW are provided via the `tgw_ram_principals` variable, typically configured in a `.tfvars` file (e.g., `shared.auto.tfvars`).
- Each participating account will need its own Terraform configuration to accept the RAM share (if required) and create a TGW attachment to this shared TGW.

## Terraform Documentation

For details on the specific resources created, input variables, and outputs generated by this configuration, please refer to the auto-generated documentation below.

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
| <a name="provider_aws.shared"></a> [aws.shared](#provider\_aws.shared) | 5.95.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_ecr_access_policy"></a> [eks\_ecr\_access\_policy](#module\_eks\_ecr\_access\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.55.0 |
| <a name="module_eks_ecr_access_role"></a> [eks\_ecr\_access\_role](#module\_eks\_ecr\_access\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.55.0 |
| <a name="module_github_actions_ecr_policy"></a> [github\_actions\_ecr\_policy](#module\_github\_actions\_ecr\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.55.0 |
| <a name="module_github_actions_role"></a> [github\_actions\_role](#module\_github\_actions\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.55.0 |
| <a name="module_github_oidc_provider"></a> [github\_oidc\_provider](#module\_github\_oidc\_provider) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider | 5.55.0 |
| <a name="module_inbound_resolver_endpoint"></a> [inbound\_resolver\_endpoint](#module\_inbound\_resolver\_endpoint) | terraform-aws-modules/route53/aws//modules/resolver-endpoints | ~> 5.0 |
| <a name="module_internal_domains_resolver_rule"></a> [internal\_domains\_resolver\_rule](#module\_internal\_domains\_resolver\_rule) | AutomateTheCloud/route53_resolver_rule/aws | 1.11.0 |
| <a name="module_outbound_resolver_endpoint"></a> [outbound\_resolver\_endpoint](#module\_outbound\_resolver\_endpoint) | terraform-aws-modules/route53/aws//modules/resolver-endpoints | ~> 5.0 |
| <a name="module_piksel_core_ecr"></a> [piksel\_core\_ecr](#module\_piksel\_core\_ecr) | terraform-aws-modules/ecr/aws | 2.4.0 |
| <a name="module_public_records"></a> [public\_records](#module\_public\_records) | terraform-aws-modules/route53/aws//modules/records | ~> 3.0 |
| <a name="module_public_zone"></a> [public\_zone](#module\_public\_zone) | terraform-aws-modules/route53/aws//modules/zones | ~> 3.0 |
| <a name="module_tgw"></a> [tgw](#module\_tgw) | terraform-aws-modules/transit-gateway/aws | ~> 2.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.21.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.21.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route.private_to_dev_via_tgw](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/route) | resource |
| [aws_route53_record.rds_domain_dev](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/route53_record) | resource |
| [aws_route53_vpc_association_authorization.dev_vpc_authorization](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/route53_vpc_association_authorization) | resource |
| [aws_route53_zone.private_hosted_zones_shared](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/resources/route53_zone) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.95/docs/data-sources/caller_identity) | data source |
| [terraform_remote_state.dev](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Image tag mutability setting for the repository (MUTABLE or IMMUTABLE) | `string` | `"IMMUTABLE"` | no |
| <a name="input_ecr_max_tagged_images"></a> [ecr\_max\_tagged\_images](#input\_ecr\_max\_tagged\_images) | Maximum number of tagged images to keep | `number` | `5` | no |
| <a name="input_ecr_untagged_image_retention_days"></a> [ecr\_untagged\_image\_retention\_days](#input\_ecr\_untagged\_image\_retention\_days) | Days to keep untagged images before expiration | `number` | `7` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (should be 'Shared' for this directory) | `string` | n/a | yes |
| <a name="input_internal_domains"></a> [internal\_domains](#input\_internal\_domains) | Map of internal domain names for private hosted zones | `map(string)` | <pre>{<br/>  "dev": "dev.piksel.internal",<br/>  "prod": "prod.piksel.internal",<br/>  "staging": "staging.piksel.internal"<br/>}</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Project name used for resource naming and tagging | `string` | n/a | yes |
| <a name="input_public_dns_records"></a> [public\_dns\_records](#input\_public\_dns\_records) | List of DNS records to create in the public hosted zone | <pre>list(object({<br/>    name    = string<br/>    type    = string<br/>    ttl     = number<br/>    records = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_public_domain_name"></a> [public\_domain\_name](#input\_public\_domain\_name) | List of public domains to create | `string` | `"piksel.big.go.id"` | no |
| <a name="input_resolver_rule_domain_name"></a> [resolver\_rule\_domain\_name](#input\_resolver\_rule\_domain\_name) | The domain name for which the central FORWARD resolver rule will apply (e.g., company.internal). This domain (and its subdomains) will be resolvable by spoke VPCs. | `string` | n/a | yes |
| <a name="input_spoke_vpc_cidrs"></a> [spoke\_vpc\_cidrs](#input\_spoke\_vpc\_cidrs) | List of CIDR blocks for spoke VPCs that need to query the inbound resolver | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| <a name="input_tgw_ram_principals"></a> [tgw\_ram\_principals](#input\_tgw\_ram\_principals) | List of AWS Account IDs or OU ARNs to share the TGW with. | `list(string)` | `[]` | no |
| <a name="input_transit_gateway_amazon_side_asn"></a> [transit\_gateway\_amazon\_side\_asn](#input\_transit\_gateway\_amazon\_side\_asn) | Private Autonomous System Number (ASN) for the Amazon side of a BGP session. Required if creating a new TGW. | `number` | `64512` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the Shared VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | The ARN of the ECR private repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | The URL of the ECR private repository |
| <a name="output_eks_ecr_access_role_arn"></a> [eks\_ecr\_access\_role\_arn](#output\_eks\_ecr\_access\_role\_arn) | ARN of the EKS role for ECR access |
| <a name="output_github_actions_role_arn"></a> [github\_actions\_role\_arn](#output\_github\_actions\_role\_arn) | ARN of the GitHub Actions role for ECR access |
| <a name="output_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#output\_github\_oidc\_provider\_arn) | ARN of the GitHub OIDC provider |
| <a name="output_github_oidc_provider_url"></a> [github\_oidc\_provider\_url](#output\_github\_oidc\_provider\_url) | URL of the GitHub OIDC provider |
| <a name="output_inbound_resolver_arn"></a> [inbound\_resolver\_arn](#output\_inbound\_resolver\_arn) | The ARN of the Inbound Resolver Endpoint. |
| <a name="output_inbound_resolver_id"></a> [inbound\_resolver\_id](#output\_inbound\_resolver\_id) | The ID of the Inbound Resolver Endpoint. |
| <a name="output_inbound_resolver_ip_addresses"></a> [inbound\_resolver\_ip\_addresses](#output\_inbound\_resolver\_ip\_addresses) | IP Addresses of the Inbound Resolver Endpoint. |
| <a name="output_inbound_resolver_security_group_id"></a> [inbound\_resolver\_security\_group\_id](#output\_inbound\_resolver\_security\_group\_id) | Security Group ID used by the Inbound Resolver Endpoint. |
| <a name="output_internal_domains_target_ips_list"></a> [internal\_domains\_target\_ips\_list](#output\_internal\_domains\_target\_ips\_list) | List of IP addresses for the inbound resolver endpoint in the shared VPC. |
| <a name="output_outbound_resolver_id"></a> [outbound\_resolver\_id](#output\_outbound\_resolver\_id) | The ID of the Outbound Resolver Endpoint. |
| <a name="output_outbound_resolver_ip_addresses"></a> [outbound\_resolver\_ip\_addresses](#output\_outbound\_resolver\_ip\_addresses) | IP Addresses of the Outbound Resolver Endpoint. |
| <a name="output_outbound_resolver_security_group_id"></a> [outbound\_resolver\_security\_group\_id](#output\_outbound\_resolver\_security\_group\_id) | Security Group ID used by the Outbound Resolver Endpoint. |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets in the Shared VPC |
| <a name="output_private_zone_arn_dev"></a> [private\_zone\_arn\_dev](#output\_private\_zone\_arn\_dev) | The ARN of the shared private hosted zone for dev |
| <a name="output_private_zone_arn_main"></a> [private\_zone\_arn\_main](#output\_private\_zone\_arn\_main) | The ARN of the main private hosted zone |
| <a name="output_private_zone_id_dev"></a> [private\_zone\_id\_dev](#output\_private\_zone\_id\_dev) | The ID of the shared private hosted zone for dev |
| <a name="output_private_zone_id_main"></a> [private\_zone\_id\_main](#output\_private\_zone\_id\_main) | The ID of the main private hosted zone |
| <a name="output_private_zone_name_server_dev"></a> [private\_zone\_name\_server\_dev](#output\_private\_zone\_name\_server\_dev) | Name servers for the shared private hosted zone for dev |
| <a name="output_private_zone_name_server_main"></a> [private\_zone\_name\_server\_main](#output\_private\_zone\_name\_server\_main) | Name servers for the main private hosted zone |
| <a name="output_private_zone_primary_name_dev"></a> [private\_zone\_primary\_name\_dev](#output\_private\_zone\_primary\_name\_dev) | The name of the shared private hosted zone for dev |
| <a name="output_private_zone_primary_name_main"></a> [private\_zone\_primary\_name\_main](#output\_private\_zone\_primary\_name\_main) | The name of the main private hosted zone |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets in the Shared VPC |
| <a name="output_public_zone_arn"></a> [public\_zone\_arn](#output\_public\_zone\_arn) | The ARN of the public hosted zone |
| <a name="output_public_zone_id"></a> [public\_zone\_id](#output\_public\_zone\_id) | The ID of the public hosted zone |
| <a name="output_public_zone_name"></a> [public\_zone\_name](#output\_public\_zone\_name) | The name of the public hosted zone |
| <a name="output_public_zone_name_servers"></a> [public\_zone\_name\_servers](#output\_public\_zone\_name\_servers) | Name servers for the public hosted zone (needed for delegation) |
| <a name="output_ram_resource_share_arn"></a> [ram\_resource\_share\_arn](#output\_ram\_resource\_share\_arn) | The ARN of the RAM Resource Share used for this resolver rule (if applicable). |
| <a name="output_rds_dev_fqdn"></a> [rds\_dev\_fqdn](#output\_rds\_dev\_fqdn) | The FQDN of the RDS dev record |
| <a name="output_rds_dev_records_name"></a> [rds\_dev\_records\_name](#output\_rds\_dev\_records\_name) | The name of the RDS dev record |
| <a name="output_resolver_rule_arn"></a> [resolver\_rule\_arn](#output\_resolver\_rule\_arn) | The ARN of the created Route 53 Resolver Rule (from AutomateTheCloud module). |
| <a name="output_resolver_rule_id"></a> [resolver\_rule\_id](#output\_resolver\_rule\_id) | The ID of the created Route 53 Resolver Rule (from AutomateTheCloud module). |
| <a name="output_resolver_rule_name"></a> [resolver\_rule\_name](#output\_resolver\_rule\_name) | The actual name of the Route 53 Resolver Rule as created by the module. |
| <a name="output_transit_gateway_arn"></a> [transit\_gateway\_arn](#output\_transit\_gateway\_arn) | The ARN of the Transit Gateway |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | The ID of the Transit Gateway |
| <a name="output_transit_gateway_subnets"></a> [transit\_gateway\_subnets](#output\_transit\_gateway\_subnets) | List of IDs of private subnets used for TGW attachments in the Shared VPC |
| <a name="output_transit_gateway_vpc_attachment"></a> [transit\_gateway\_vpc\_attachment](#output\_transit\_gateway\_vpc\_attachment) | Map of Transit Gateway VPC Attachment attributes |
| <a name="output_transit_gateway_vpc_attachment_ids"></a> [transit\_gateway\_vpc\_attachment\_ids](#output\_transit\_gateway\_vpc\_attachment\_ids) | List of Transit Gateway VPC Attachment identifiers |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the Shared VPC |
| <a name="output_vpc_endpoint_dns_entry"></a> [vpc\_endpoint\_dns\_entry](#output\_vpc\_endpoint\_dns\_entry) | Map of VPC Endpoint DNS entries |
| <a name="output_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#output\_vpc\_endpoint\_ids) | Map of VPC Endpoint IDs created in the Shared VPC |
| <a name="output_vpc_endpoint_network_interface_ids"></a> [vpc\_endpoint\_network\_interface\_ids](#output\_vpc\_endpoint\_network\_interface\_ids) | Map of VPC Endpoint Network Interface IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the Shared VPC |
<!-- END_TF_DOCS -->
