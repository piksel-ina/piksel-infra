<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.stac_write_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.stacread_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.stac_write_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.stacread_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [kubernetes_namespace.stac](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.stacread_namespace_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_password.stac_read](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.stac_write](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_stac_namespace"></a> [stac\_namespace](#output\_stac\_namespace) | Kubernetes namespace where STAC is deployed. |
| <a name="output_stac_read_db_password"></a> [stac\_read\_db\_password](#output\_stac\_read\_db\_password) | STAC read database password. |
| <a name="output_stac_read_secret_arn"></a> [stac\_read\_secret\_arn](#output\_stac\_read\_secret\_arn) | ARN of the AWS Secrets Manager secret for STAC read credentials. |
| <a name="output_stac_write_db_password"></a> [stac\_write\_db\_password](#output\_stac\_write\_db\_password) | STAC write database password. |
| <a name="output_stac_write_secret_arn"></a> [stac\_write\_secret\_arn](#output\_stac\_write\_secret\_arn) | ARN of the AWS Secrets Manager secret for STAC write credentials. |
| <a name="output_stacread_k8s_secret_name"></a> [stacread\_k8s\_secret\_name](#output\_stacread\_k8s\_secret\_name) | Kubernetes secret name for STAC read credentials. |
<!-- END_TF_DOCS -->
