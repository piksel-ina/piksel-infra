<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_route.spoke_to_shared_vpc_via_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnets | `list(string)` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_spoke_vpc_route_table_id"></a> [spoke\_vpc\_route\_table\_id](#input\_spoke\_vpc\_route\_table\_id) | Route table ID for this spoke VPC | `list(string)` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | ID of the shared Transit Gateway from hub account | `string` | n/a | yes |
| <a name="input_vpc_cidr_shared"></a> [vpc\_cidr\_shared](#input\_vpc\_cidr\_shared) | CIDR block for the hub VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to associate with the resolver rule | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_spoke_to_shared_vpc_via_tgw_route_id"></a> [spoke\_to\_shared\_vpc\_via\_tgw\_route\_id](#output\_spoke\_to\_shared\_vpc\_via\_tgw\_route\_id) | The ID of the route to the shared VPC via Transit Gateway |
| <a name="output_spoke_to_shared_vpc_via_tgw_route_state"></a> [spoke\_to\_shared\_vpc\_via\_tgw\_route\_state](#output\_spoke\_to\_shared\_vpc\_via\_tgw\_route\_state) | The state of the route to the shared VPC via Transit Gateway |
| <a name="output_tgw_attachment_arn"></a> [tgw\_attachment\_arn](#output\_tgw\_attachment\_arn) | The ARN of the Transit Gateway attachment |
| <a name="output_tgw_attachment_id"></a> [tgw\_attachment\_id](#output\_tgw\_attachment\_id) | The ID of the Transit Gateway attachment |
| <a name="output_tgw_vpc_owner_id"></a> [tgw\_vpc\_owner\_id](#output\_tgw\_vpc\_owner\_id) | The owner ID of the Transit Gateway attachment |
<!-- END_TF_DOCS -->
