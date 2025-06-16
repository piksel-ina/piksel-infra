# ExternalDNS and FluxCD Notification Setup for EKS

This Terraform module configures and deploys ExternalDNS to an AWS EKS cluster. It also includes resources for setting up FluxCD Slack notifications.

## Overview

This module automates the following:

1.  **ExternalDNS Deployment**:

    - Creates a dedicated Kubernetes namespace (`aws-external-dns-helm`).
    - Sets up an IAM Role for Service Account (IRSA) for ExternalDNS pods. This role is granted permissions to:
      - List Route53 hosted zones and record sets.
      - Change resource record sets in specific, pre-configured hosted zones.
      - Assume a cross-account IAM role located in a shared AWS account for managing DNS records.
    - Deploys ExternalDNS using the official Helm chart, configured to:
      - Use the created service account with IRSA.
      - Assume the specified cross-account IAM role for Route53 operations.
      - Monitor services and ingresses to synchronize DNS records.

&nbsp;<figure>
<img src="../.images/externalDNS.png"
         alt="ExternalDNS setup diagram for piksel project" width="750" height="auto">

  <figcaption><i>Figure: ExternalDNS configuration diagram for piksel eks cluster</i></figcaption>
</figure>

For more comprehensive explanation please refer to [**📑 ExternalDNS Detail Documentation**](https://github.com/piksel-ina/piksel-document/blob/main/architecture/eks-addons.md)

2.  **FluxCD Notification Setup**:
    - Creates the `flux-system` Kubernetes namespace if it doesn't exist.
    - Fetches a Slack webhook URL from AWS Secrets Manager.
    - Creates a Kubernetes secret (`slack-webhook`) in the `flux-system` namespace containing the webhook URL, enabling FluxCD to send notifications to Slack.

<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

## Providers

| Name                                                                  | Version |
| --------------------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)                      | n/a     |
| <a name="provider_helm"></a> [helm](#provider_helm)                   | n/a     |
| <a name="provider_kubernetes"></a> [kubernetes](#provider_kubernetes) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                            | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_iam_role.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                               | resource    |
| [aws_iam_role_policy.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                                 | resource    |
| [aws_iam_role_policy.external_dns_assume_crossaccount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)             | resource    |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                               | resource    |
| [kubernetes_namespace.external_dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace)                               | resource    |
| [kubernetes_namespace.flux_system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace)                                | resource    |
| [kubernetes_secret.slack_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret)                                    | resource    |
| [aws_iam_policy_document.external_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                      | data source |
| [aws_secretsmanager_secret_version.slack_webhook](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name                                                                                                                                 | Description                                              | Type           | Default | Required |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- | -------------- | ------- | :------: |
| <a name="input_aws_partition"></a> [aws_partition](#input_aws_partition)                                                             | The AWS partition                                        | `string`       | `"aws"` |    no    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                                                                      | AWS region                                               | `string`       | n/a     |   yes    |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name)                                                                | Name of the EKS cluster                                  | `string`       | n/a     |   yes    |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                                                                | Default tags                                             | `any`          | n/a     |   yes    |
| <a name="input_environment"></a> [environment](#input_environment)                                                                   | The name of the environment                              | `string`       | n/a     |   yes    |
| <a name="input_externaldns_crossaccount_role_arn"></a> [externaldns_crossaccount_role_arn](#input_externaldns_crossaccount_role_arn) | The ARN of the cross-account IAM role in Route53 account | `string`       | n/a     |   yes    |
| <a name="input_oidc_provider"></a> [oidc_provider](#input_oidc_provider)                                                             | EKS Cluster OIDC provider issuer                         | `any`          | n/a     |   yes    |
| <a name="input_oidc_provider_arn"></a> [oidc_provider_arn](#input_oidc_provider_arn)                                                 | EKS Cluster OIDC provider arn                            | `any`          | n/a     |   yes    |
| <a name="input_project"></a> [project](#input_project)                                                                               | The name of the project                                  | `string`       | n/a     |   yes    |
| <a name="input_subdomains"></a> [subdomains](#input_subdomains)                                                                      | List of domain filters for ExternalDNS                   | `list(string)` | n/a     |   yes    |
| <a name="input_zone_ids"></a> [zone_ids](#input_zone_ids)                                                                            | Map of domain name to Route53 hosted zone IDs            | `any`          | n/a     |   yes    |

## Outputs

| Name                                                                                                                                         | Description                                                        |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| <a name="output_external_dns_helm_chart_version"></a> [external_dns_helm_chart_version](#output_external_dns_helm_chart_version)             | Version of the External DNS Helm chart deployed                    |
| <a name="output_external_dns_helm_release_name"></a> [external_dns_helm_release_name](#output_external_dns_helm_release_name)                | Name of the Helm release for External DNS                          |
| <a name="output_external_dns_helm_release_namespace"></a> [external_dns_helm_release_namespace](#output_external_dns_helm_release_namespace) | Namespace of the Helm release for External DNS                     |
| <a name="output_external_dns_helm_release_status"></a> [external_dns_helm_release_status](#output_external_dns_helm_release_status)          | Status of the Helm release for External DNS                        |
| <a name="output_external_dns_iam_role_arn"></a> [external_dns_iam_role_arn](#output_external_dns_iam_role_arn)                               | ARN of the IAM role created for External DNS                       |
| <a name="output_external_dns_namespace"></a> [external_dns_namespace](#output_external_dns_namespace)                                        | Namespace where External DNS is deployed                           |
| <a name="output_external_dns_service_account_name"></a> [external_dns_service_account_name](#output_external_dns_service_account_name)       | Name of the service account used by External DNS (managed by Helm) |
| <a name="output_flux_namespace"></a> [flux_namespace](#output_flux_namespace)                                                                | The namespace where Flux is deployed                               |
| <a name="output_slack_webhook_address"></a> [slack_webhook_address](#output_slack_webhook_address)                                           | The Slack webhook address used for notifications                   |
| <a name="output_slack_webhook_secret_name"></a> [slack_webhook_secret_name](#output_slack_webhook_secret_name)                               | Slack webhook secret name                                          |

<!-- END_TF_DOCS -->
