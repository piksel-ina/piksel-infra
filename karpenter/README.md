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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_service_linked_role.ec2_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.karpenter_node_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.karpenter_node_pool](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.karpenter_node_pool_gpu](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | value | `any` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of EKS Cluster | `any` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | value | `map` | `{}` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | value | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_karpenter_helm_release_status"></a> [karpenter\_helm\_release\_status](#output\_karpenter\_helm\_release\_status) | The status of the Karpenter Helm release |
| <a name="output_karpenter_iam_role_arn"></a> [karpenter\_iam\_role\_arn](#output\_karpenter\_iam\_role\_arn) | The ARN of the Karpenter IAM role |
| <a name="output_karpenter_interruption_queue_name"></a> [karpenter\_interruption\_queue\_name](#output\_karpenter\_interruption\_queue\_name) | The name of the Karpenter interruption SQS queue |
| <a name="output_karpenter_node_class_name"></a> [karpenter\_node\_class\_name](#output\_karpenter\_node\_class\_name) | The name of the Karpenter EC2NodeClass. |
| <a name="output_karpenter_node_class_status"></a> [karpenter\_node\_class\_status](#output\_karpenter\_node\_class\_status) | Status of the Karpenter EC2NodeClass. |
| <a name="output_karpenter_node_iam_role_name"></a> [karpenter\_node\_iam\_role\_name](#output\_karpenter\_node\_iam\_role\_name) | The name of the Karpenter node IAM role |
| <a name="output_karpenter_node_pool_gpu_name"></a> [karpenter\_node\_pool\_gpu\_name](#output\_karpenter\_node\_pool\_gpu\_name) | The name of the GPU Karpenter NodePool. |
| <a name="output_karpenter_node_pool_name"></a> [karpenter\_node\_pool\_name](#output\_karpenter\_node\_pool\_name) | The name of the default Karpenter NodePool. |
<!-- END_TF_DOCS -->
