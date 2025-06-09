<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 5.3.0 |
| <a name="module_spoke_sg"></a> [spoke\_sg](#module\_spoke\_sg) | terraform-aws-modules/security-group/aws | 5.3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block of the deployment vpc | `string` | n/a | yes |
| <a name="input_vpc_cidr_shared"></a> [vpc\_cidr\_shared](#input\_vpc\_cidr\_shared) | CIDR block for the hub VPCs | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to associate with the security group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_group_arn_database"></a> [security\_group\_arn\_database](#output\_security\_group\_arn\_database) | The ARN of the security group |
| <a name="output_security_group_arn_hub_to_spoke"></a> [security\_group\_arn\_hub\_to\_spoke](#output\_security\_group\_arn\_hub\_to\_spoke) | The ARN of the security group |
| <a name="output_security_group_description_database"></a> [security\_group\_description\_database](#output\_security\_group\_description\_database) | The description of the security group |
| <a name="output_security_group_description_hub_to_spoke"></a> [security\_group\_description\_hub\_to\_spoke](#output\_security\_group\_description\_hub\_to\_spoke) | The description of the security group |
| <a name="output_security_group_id_database"></a> [security\_group\_id\_database](#output\_security\_group\_id\_database) | The ID of the security group |
| <a name="output_security_group_id_hub_to_spoke"></a> [security\_group\_id\_hub\_to\_spoke](#output\_security\_group\_id\_hub\_to\_spoke) | The ID of the security group |
| <a name="output_security_group_name_database"></a> [security\_group\_name\_database](#output\_security\_group\_name\_database) | The name of the security group |
| <a name="output_security_group_name_hub_to_spoke"></a> [security\_group\_name\_hub\_to\_spoke](#output\_security\_group\_name\_hub\_to\_spoke) | The name of the security group |
<!-- END_TF_DOCS -->
