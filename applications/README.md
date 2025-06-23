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
| <a name="module_iam_eks_role_hub_reader"></a> [iam\_eks\_role\_hub\_reader](#module\_iam\_eks\_role\_hub\_reader) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.grafana_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.hub_user_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.grafana_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.grafana_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.jupyterhub_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.grafana_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.jupyterhub_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [kubernetes_namespace.flux_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.hub](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.monitoring](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.grafana_admin_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.hub-dask-token](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.hub_db_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.jupyterhub](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.slack_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.hub_user_read](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [random_bytes.grafana_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/bytes) | resource |
| [random_id.jhub_hub_cookie_secret_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.jhub_proxy_secret_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.dask_gateway_api_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.grafana_random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.jupyterhub_random_string](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_iam_policy_document.grafana_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.grafana_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret_version.grafana_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.hub_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.slack_webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auth0_tenant"></a> [auth0\_tenant](#input\_auth0\_tenant) | The Auth0 tenant URL | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"ap-southeast-3"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster for tagging subnets | `string` | `"piksel-eks-cluster"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | The OIDC issuer ARN for the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_k8s_db_service"></a> [k8s\_db\_service](#input\_k8s\_db\_service) | Kubernetes database service FQDN | `string` | n/a | yes |
| <a name="input_oidc_issuer_url"></a> [oidc\_issuer\_url](#input\_oidc\_issuer\_url) | The OIDC issuer URL for the EKS cluster | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | The name of the project | `string` | n/a | yes |
| <a name="input_subdomains"></a> [subdomains](#input\_subdomains) | Subdomains for the EKS cluster | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flux_namespace"></a> [flux\_namespace](#output\_flux\_namespace) | The namespace where Flux is deployed |
| <a name="output_grafana_admin_secret_name"></a> [grafana\_admin\_secret\_name](#output\_grafana\_admin\_secret\_name) | The name of the Kubernetes secret storing the Grafana admin credentials. |
| <a name="output_grafana_cloudwatch_policy_arn"></a> [grafana\_cloudwatch\_policy\_arn](#output\_grafana\_cloudwatch\_policy\_arn) | The IAM policy ARN attached to Grafana for CloudWatch access. |
| <a name="output_grafana_db_password"></a> [grafana\_db\_password](#output\_grafana\_db\_password) | The Grafana database password. |
| <a name="output_grafana_db_password_secret_arn"></a> [grafana\_db\_password\_secret\_arn](#output\_grafana\_db\_password\_secret\_arn) | The ARN of the AWS Secrets Manager secret storing the Grafana DB password. |
| <a name="output_grafana_iam_role_arn"></a> [grafana\_iam\_role\_arn](#output\_grafana\_iam\_role\_arn) | The IAM role ARN used by Grafana for IRSA (CloudWatch access). |
| <a name="output_grafana_namespace"></a> [grafana\_namespace](#output\_grafana\_namespace) | The Kubernetes namespace where Grafana is deployed. |
| <a name="output_grafana_oauth_client_secret_arn"></a> [grafana\_oauth\_client\_secret\_arn](#output\_grafana\_oauth\_client\_secret\_arn) | The ARN of the AWS Secrets Manager secret for the Grafana OAuth client/secret. |
| <a name="output_grafana_values_secret_name"></a> [grafana\_values\_secret\_name](#output\_grafana\_values\_secret\_name) | The name of the Kubernetes secret containing the Grafana Helm values. |
| <a name="output_jupyterhub_db_password"></a> [jupyterhub\_db\_password](#output\_jupyterhub\_db\_password) | The JupyterHub database password |
| <a name="output_jupyterhub_db_secret_arn"></a> [jupyterhub\_db\_secret\_arn](#output\_jupyterhub\_db\_secret\_arn) | ARN of the JupyterHub database password secret in AWS Secrets Manager |
| <a name="output_jupyterhub_irsa_arn"></a> [jupyterhub\_irsa\_arn](#output\_jupyterhub\_irsa\_arn) | IAM Role ARN for JupyterHub user-read service account (IRSA) |
| <a name="output_jupyterhub_namespace"></a> [jupyterhub\_namespace](#output\_jupyterhub\_namespace) | The namespace where JupyterHub is deployed |
| <a name="output_jupyterhub_service_account_name"></a> [jupyterhub\_service\_account\_name](#output\_jupyterhub\_service\_account\_name) | Kubernetes service account name for S3 read access |
| <a name="output_jupyterhub_subdomain"></a> [jupyterhub\_subdomain](#output\_jupyterhub\_subdomain) | The public subdomain for JupyterHub |
| <a name="output_slack_webhook_secret_name"></a> [slack\_webhook\_secret\_name](#output\_slack\_webhook\_secret\_name) | Slack webhook secret name |
<!-- END_TF_DOCS -->
