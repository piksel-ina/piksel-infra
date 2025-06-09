<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.external_dns_assume_crossaccount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.external_dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.flux_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.slack_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret_version.slack_webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_partition"></a> [aws\_partition](#input\_aws\_partition) | The AWS partition | `string` | `"aws"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags | `any` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_externaldns_crossaccount_role_arn"></a> [externaldns\_crossaccount\_role\_arn](#input\_externaldns\_crossaccount\_role\_arn) | The ARN of the cross-account IAM role in Route53 account | `string` | n/a | yes |
| <a name="input_oidc_provider"></a> [oidc\_provider](#input\_oidc\_provider) | EKS Cluster OIDC provider issuer | `any` | n/a | yes |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | EKS Cluster OIDC provider arn | `any` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of domain filters for ExternalDNS | `list(string)` | n/a | yes |
| <a name="input_zone_ids"></a> [zone\_ids](#input\_zone\_ids) | Map of domain name to Route53 hosted zone IDs | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_dns_helm_chart_version"></a> [external\_dns\_helm\_chart\_version](#output\_external\_dns\_helm\_chart\_version) | Version of the External DNS Helm chart deployed |
| <a name="output_external_dns_helm_release_name"></a> [external\_dns\_helm\_release\_name](#output\_external\_dns\_helm\_release\_name) | Name of the Helm release for External DNS |
| <a name="output_external_dns_helm_release_namespace"></a> [external\_dns\_helm\_release\_namespace](#output\_external\_dns\_helm\_release\_namespace) | Namespace of the Helm release for External DNS |
| <a name="output_external_dns_helm_release_status"></a> [external\_dns\_helm\_release\_status](#output\_external\_dns\_helm\_release\_status) | Status of the Helm release for External DNS |
| <a name="output_external_dns_iam_role_arn"></a> [external\_dns\_iam\_role\_arn](#output\_external\_dns\_iam\_role\_arn) | ARN of the IAM role created for External DNS |
| <a name="output_external_dns_namespace"></a> [external\_dns\_namespace](#output\_external\_dns\_namespace) | Namespace where External DNS is deployed |
| <a name="output_external_dns_service_account_name"></a> [external\_dns\_service\_account\_name](#output\_external\_dns\_service\_account\_name) | Name of the service account used by External DNS (managed by Helm) |
| <a name="output_flux_namespace"></a> [flux\_namespace](#output\_flux\_namespace) | The namespace where Flux is deployed |
| <a name="output_slack_webhook_address"></a> [slack\_webhook\_address](#output\_slack\_webhook\_address) | The Slack webhook address used for notifications |
| <a name="output_slack_webhook_secret_name"></a> [slack\_webhook\_secret\_name](#output\_slack\_webhook\_secret\_name) | Slack webhook secret name |
<!-- END_TF_DOCS -->
