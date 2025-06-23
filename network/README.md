<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_spoke_sg"></a> [spoke\_sg](#module\_spoke\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.21.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_route.spoke_to_shared_vpc_via_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_zone_association.vpc_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_vpc_dhcp_options.spoke_dhcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.spoke_dhcp_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Number of Availability Zones to use for subnets | `number` | `2` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster for tagging subnets | `string` | `"piksel-eks-cluster"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_enable_flow_log"></a> [enable\_flow\_log](#input\_enable\_flow\_log) | Enable VPC Flow Logs for monitoring network traffic | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | Retention period for VPC Flow Logs in CloudWatch (in days) | `number` | `90` | no |
| <a name="input_inbound_resolver_ip_addresses"></a> [inbound\_resolver\_ip\_addresses](#input\_inbound\_resolver\_ip\_addresses) | List of inbound resolver ip addresses | `any` | n/a | yes |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Enable one NAT Gateway per Availability Zone (higher availability, higher cost) | `bool` | `false` | no |
| <a name="input_private_subnet_bits"></a> [private\_subnet\_bits](#input\_private\_subnet\_bits) | Number of bits to allocate for private subnet CIDR | `number` | `2` | no |
| <a name="input_private_zone_ids"></a> [private\_zone\_ids](#input\_private\_zone\_ids) | The ID of the private hosted zone | `map(string)` | `{}` | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_public_subnet_bits"></a> [public\_subnet\_bits](#input\_public\_subnet\_bits) | Number of bits to allocate for public subnet CIDR | `number` | `8` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Enable a single NAT Gateway for all private subnets (cheaper, less availability) | `bool` | `true` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | ID of the shared Transit Gateway from hub account | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_cidr_shared"></a> [vpc\_cidr\_shared](#input\_vpc\_cidr\_shared) | CIDR block for the hub VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | --- Account Identifier --- |
| <a name="output_azs"></a> [azs](#output\_azs) | List of Availability Zones used for subnets |
| <a name="output_dhcp_options"></a> [dhcp\_options](#output\_dhcp\_options) | DHCP Option Outputs |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | List of public IPs of NAT Gateways |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | List of NAT Gateway IDs |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of IDs of private route tables |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | List of CIDR blocks of private subnets |
| <a name="output_private_zone_association_id"></a> [private\_zone\_association\_id](#output\_private\_zone\_association\_id) | The account ID of the account that created the hosted zone |
| <a name="output_private_zone_association_owner_id"></a> [private\_zone\_association\_owner\_id](#output\_private\_zone\_association\_owner\_id) | The account ID of the account that created the hosted zone |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | List of IDs of public route tables |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#output\_public\_subnets\_cidr\_blocks) | List of CIDR blocks of public subnets |
| <a name="output_security_group_arn_hub_to_spoke"></a> [security\_group\_arn\_hub\_to\_spoke](#output\_security\_group\_arn\_hub\_to\_spoke) | The ARN of the security group |
| <a name="output_security_group_description_hub_to_spoke"></a> [security\_group\_description\_hub\_to\_spoke](#output\_security\_group\_description\_hub\_to\_spoke) | The description of the security group |
| <a name="output_security_group_id_hub_to_spoke"></a> [security\_group\_id\_hub\_to\_spoke](#output\_security\_group\_id\_hub\_to\_spoke) | The ID of the security group |
| <a name="output_security_group_name_hub_to_spoke"></a> [security\_group\_name\_hub\_to\_spoke](#output\_security\_group\_name\_hub\_to\_spoke) | The name of the security group |
| <a name="output_spoke_to_shared_vpc_via_tgw_route_id"></a> [spoke\_to\_shared\_vpc\_via\_tgw\_route\_id](#output\_spoke\_to\_shared\_vpc\_via\_tgw\_route\_id) | The ID of the route to the shared VPC via Transit Gateway |
| <a name="output_spoke_to_shared_vpc_via_tgw_route_state"></a> [spoke\_to\_shared\_vpc\_via\_tgw\_route\_state](#output\_spoke\_to\_shared\_vpc\_via\_tgw\_route\_state) | The state of the route to the shared VPC via Transit Gateway |
| <a name="output_tgw_attachment_arn"></a> [tgw\_attachment\_arn](#output\_tgw\_attachment\_arn) | The ARN of the Transit Gateway attachment |
| <a name="output_tgw_attachment_id"></a> [tgw\_attachment\_id](#output\_tgw\_attachment\_id) | The ID of the Transit Gateway attachment |
| <a name="output_tgw_vpc_owner_id"></a> [tgw\_vpc\_owner\_id](#output\_tgw\_vpc\_owner\_id) | The owner ID of the Transit Gateway attachment |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_vpc_flow_log_cloudwatch_iam_role_arn"></a> [vpc\_flow\_log\_cloudwatch\_iam\_role\_arn](#output\_vpc\_flow\_log\_cloudwatch\_iam\_role\_arn) | ARN of the CloudWatch Log Group for Flow Logs (if enabled) |
| <a name="output_vpc_flow_log_id"></a> [vpc\_flow\_log\_id](#output\_vpc\_flow\_log\_id) | ID of the VPC Flow Log (if enabled) |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of the VPC |
<!-- END_TF_DOCS -->
