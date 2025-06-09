<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_aws.cross_account"></a> [aws.cross\_account](#provider\_aws.cross\_account) | n/a |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_eks_role_bucket"></a> [iam\_eks\_role\_bucket](#module\_iam\_eks\_role\_bucket) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.ows_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_iam_policy.read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.odc_cloudfront_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.odc_cloudfront_assume_crossaccount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_route53_record.ows_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.odc_read_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.odc_write_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.odc_read_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.odc_write_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [kubernetes_namespace.odc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.odcread_namespace_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_password.odc_read](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.odc_write](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The OIDC issuer ARN for the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_internal_buckets"></a> [internal\_buckets](#input\_internal\_buckets) | List of internal S3 bucket names | `list(string)` | `[]` | no |
| <a name="input_odc_cloudfront_crossaccount_role_arn"></a> [odc\_cloudfront\_crossaccount\_role\_arn](#input\_odc\_cloudfront\_crossaccount\_role\_arn) | value of the cross-account IAM role in CloudFront account | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_public_hosted_zone_id"></a> [public\_hosted\_zone\_id](#input\_public\_hosted\_zone\_id) | The ID of the public hosted zone | `string` | n/a | yes |
| <a name="input_read_external_buckets"></a> [read\_external\_buckets](#input\_read\_external\_buckets) | List of external S3 bucket names | `list(string)` | `[]` | no |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | List of subdomains for the project | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_odc_data_reader_role_arn"></a> [odc\_data\_reader\_role\_arn](#output\_odc\_data\_reader\_role\_arn) | IAM role ARN for ODC data reader |
| <a name="output_odc_namespace"></a> [odc\_namespace](#output\_odc\_namespace) | Kubernetes namespace for ODC |
| <a name="output_odc_read_db_password"></a> [odc\_read\_db\_password](#output\_odc\_read\_db\_password) | ODC read database password |
| <a name="output_odc_read_password_secret_arn"></a> [odc\_read\_password\_secret\_arn](#output\_odc\_read\_password\_secret\_arn) | Secrets Manager ARN for ODC read password |
| <a name="output_odc_write_db_password"></a> [odc\_write\_db\_password](#output\_odc\_write\_db\_password) | ODC write database password |
| <a name="output_odc_write_password_secret_arn"></a> [odc\_write\_password\_secret\_arn](#output\_odc\_write\_password\_secret\_arn) | Secrets Manager ARN for ODC write password |
<!-- END_TF_DOCS -->
