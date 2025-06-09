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
| [aws_route53_zone_association.vpc_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_vpc_dhcp_options.spoke_dhcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.spoke_dhcp_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_inbound_resolver_ip_addresses"></a> [inbound\_resolver\_ip\_addresses](#input\_inbound\_resolver\_ip\_addresses) | List of inbound resolver ip addresses | `any` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to associate with the resolver rule | `string` | n/a | yes |
| <a name="input_zone_ids"></a> [zone\_ids](#input\_zone\_ids) | Maps of Route53 Hosted Zone IDs to associate with the VPC | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dhcp_options"></a> [dhcp\_options](#output\_dhcp\_options) | DHCP Option Outputs |
| <a name="output_private_zone_association_id"></a> [private\_zone\_association\_id](#output\_private\_zone\_association\_id) | The account ID of the account that created the hosted zone |
| <a name="output_private_zone_association_owner_id"></a> [private\_zone\_association\_owner\_id](#output\_private\_zone\_association\_owner\_id) | The account ID of the account that created the hosted zone |
<!-- END_TF_DOCS -->
