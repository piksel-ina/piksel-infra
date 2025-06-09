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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_eks_role_bucket"></a> [iam\_eks\_role\_bucket](#module\_iam\_eks\_role\_bucket) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.argo_artifact_read_write_access_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.argo_artifact_read_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.argo_artifact_read_write_policy_more](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.argo_artifact_read_write_role_more](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.argo_artifact_read_write_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.argo_artifact_read_write_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.argo_artifact_read_write_user_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_s3_bucket.argo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_secretsmanager_secret.argo_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.argo_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [kubernetes_namespace.argo_workflow](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_role_binding.argo_artifact](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_secret.argo_artifact_read_write](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.argo_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.argo_server_sso](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.grafana_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.jupyterhub_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.odc_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.odcread_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.stac_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.stacread_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.argo_artifact](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [random_password.argo_random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_secretsmanager_secret_version.argo_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster for tagging subnets | `string` | `"piksel-eks-cluster"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The OIDC issuer ARN for the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_grafana_secret"></a> [grafana\_secret](#input\_grafana\_secret) | Secret for Grafana | `string` | n/a | yes |
| <a name="input_jupyterhub_secret"></a> [jupyterhub\_secret](#input\_jupyterhub\_secret) | Secret for JupyterHub | `string` | n/a | yes |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | The maximum session duration for the role | `number` | `10800` | no |
| <a name="input_odc_secret"></a> [odc\_secret](#input\_odc\_secret) | Secret for ODC write access | `string` | n/a | yes |
| <a name="input_odcread_secret"></a> [odcread\_secret](#input\_odcread\_secret) | Secret for ODC read-only access | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_stac_secret"></a> [stac\_secret](#input\_stac\_secret) | Secret for STAC write access | `string` | n/a | yes |
| <a name="input_stacread_secret"></a> [stacread\_secret](#input\_stacread\_secret) | Secret for STAC read-only access | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argo_artifact_bucket_name"></a> [argo\_artifact\_bucket\_name](#output\_argo\_artifact\_bucket\_name) | The name of the S3 bucket for Argo artifacts. |
| <a name="output_argo_artifact_iam_policy_arn"></a> [argo\_artifact\_iam\_policy\_arn](#output\_argo\_artifact\_iam\_policy\_arn) | The ARN of the IAM policy for S3 read/write access. |
| <a name="output_argo_artifact_iam_role_arn"></a> [argo\_artifact\_iam\_role\_arn](#output\_argo\_artifact\_iam\_role\_arn) | The ARN of the IAM role assumed by the Argo artifact service account (IRSA). |
| <a name="output_argo_artifact_k8s_secret_name"></a> [argo\_artifact\_k8s\_secret\_name](#output\_argo\_artifact\_k8s\_secret\_name) | Kubernetes secret containing Argo artifact user credentials. |
| <a name="output_argo_artifact_policy_arn_for_user"></a> [argo\_artifact\_policy\_arn\_for\_user](#output\_argo\_artifact\_policy\_arn\_for\_user) | The ARN of the policy that allows read/write access to the Argo artifact bucket. |
| <a name="output_argo_artifact_role_arn_for_user"></a> [argo\_artifact\_role\_arn\_for\_user](#output\_argo\_artifact\_role\_arn\_for\_user) | The IAM role ARN for Argo artifact read/write. |
| <a name="output_argo_artifact_role_name_for_user"></a> [argo\_artifact\_role\_name\_for\_user](#output\_argo\_artifact\_role\_name\_for\_user) | The IAM role name for Argo artifact read/write. |
| <a name="output_argo_artifact_service_account_name"></a> [argo\_artifact\_service\_account\_name](#output\_argo\_artifact\_service\_account\_name) | The name of the Kubernetes service account used by Argo for artifact access. |
| <a name="output_argo_artifact_user_name"></a> [argo\_artifact\_user\_name](#output\_argo\_artifact\_user\_name) | The IAM user name for Argo artifact read/write. |
| <a name="output_argo_db_password_secret_arn"></a> [argo\_db\_password\_secret\_arn](#output\_argo\_db\_password\_secret\_arn) | The ARN of the AWS Secrets Manager secret storing the Argo DB password. |
| <a name="output_argo_k8s_secret_name"></a> [argo\_k8s\_secret\_name](#output\_argo\_k8s\_secret\_name) | The name of the Kubernetes secret containing the Auth0 client secret. |
| <a name="output_argo_workflow_namespace"></a> [argo\_workflow\_namespace](#output\_argo\_workflow\_namespace) | The namespace for all Argo resources. |
<!-- END_TF_DOCS -->
