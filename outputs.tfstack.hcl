# --- Data Source ---
output "account_id" {
  type        = string
  description = "The AWS account ID"
  value       = component.vpc.account_id
}

output "network_metadata" {
  description = "Grouped network and connectivity metadata"
  type = object({
    vpc = object({
      id                               = string
      cidr_block                       = string
      flow_log_id                      = string
      flow_log_cloudwatch_iam_role_arn = string
    })
    subnets = object({
      public_ids          = list(string)
      public_cidr_blocks  = list(string)
      private_ids         = list(string)
      private_cidr_blocks = list(string)
    })
    nat = object({
      ids        = list(string)
      public_ips = list(string)
    })
    route_tables = object({
      public_ids  = list(string)
      private_ids = list(string)
    })
    route53 = object({
      private_zone_association_id = list(string)
    })
    transit_gateway = object({
      attachment_arn                          = string
      attachment_id                           = string
      vpc_owner_id                            = string
      spoke_to_shared_vpc_via_tgw_route_id    = list(string)
      spoke_to_shared_vpc_via_tgw_route_state = list(string)
    })
  })
  value = {
    vpc = {
      id                               = component.vpc.vpc_id
      cidr_block                       = component.vpc.vpc_cidr_block
      flow_log_id                      = component.vpc.vpc_flow_log_id
      flow_log_cloudwatch_iam_role_arn = component.vpc.vpc_flow_log_cloudwatch_iam_role_arn
    }
    subnets = {
      public_ids          = component.vpc.public_subnets
      public_cidr_blocks  = component.vpc.public_subnets_cidr_blocks
      private_ids         = component.vpc.private_subnets
      private_cidr_blocks = component.vpc.private_subnets_cidr_blocks
    }
    nat = {
      ids        = component.vpc.natgw_ids
      public_ips = component.vpc.nat_public_ips
    }
    route_tables = {
      public_ids  = component.vpc.public_route_table_ids
      private_ids = component.vpc.private_route_table_ids
    }
    route53 = {
      private_zone_association_id = component.phz_association.private_zone_association_id
    }
    transit_gateway = {
      attachment_arn                          = component.tgw-spoke.tgw_attachment_arn
      attachment_id                           = component.tgw-spoke.tgw_attachment_id
      vpc_owner_id                            = component.tgw-spoke.tgw_vpc_owner_id
      spoke_to_shared_vpc_via_tgw_route_id    = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_id
      spoke_to_shared_vpc_via_tgw_route_state = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_state
    }
  }
}

# --- Security Group Outputs ---
output security_group_metadata_hub_to_spoke {
  description = "Output the security group"
  type = object({
    arn         = string
    id          = string
    name        = string
    description = string
  })
  value = {
    arn         = component.security_group.security_group_arn_hub_to_spoke
    id          = component.security_group.security_group_id_hub_to_spoke
    name        = component.security_group.security_group_name_hub_to_spoke
    description = component.security_group.security_group_description_hub_to_spoke
  }
}

output security_group_metadata_database {
  description = "Output the security group"
  type = object({
    arn         = string
    id          = string
    name        = string
    description = string
  })
  value = {
    arn         = component.security_group.security_group_arn_database
    id          = component.security_group.security_group_id_database
    name        = component.security_group.security_group_name_database
    description = component.security_group.security_group_description_database
  }
}

# --- EKS Cluster Outputs ---
output "eks_cluster_metadata" {
  description = "Output of EKS Cluster"
  type = object({
    name                  = string
    endpoint              = string
    certificate_authority = string
    oidc_provider_arn     = string
    oidc_issuer_url       = string
    tls_fingerprint       = string
  })
  value = {
    name                  = component.eks-cluster.cluster_name
    endpoint              = component.eks-cluster.cluster_endpoint
    certificate_authority = component.eks-cluster.cluster_certificate_authority_data
    oidc_provider_arn     = component.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url       = component.eks-cluster.cluster_oidc_issuer_url
    tls_fingerprint       = component.eks-cluster.cluster_tls_certificate_sha1_fingerprint
  }
}

# --- Karpenter Outputs ---
output "karpenter_metadata" {
  description = "Output of Karpenter configuration and resources"
  type = object({
    iam_role_arn            = string
    node_iam_role_name      = string
    interruption_queue_name = string
    helm_release_status     = string
    node_class_name         = optional(string)
    node_pool_name          = optional(string)
    # node_pool_gpu_name      = optional(string)
    node_class_status = optional(map(string))
  })
  value = {
    iam_role_arn            = component.karpenter.karpenter_iam_role_arn
    node_iam_role_name      = component.karpenter.karpenter_node_iam_role_name
    interruption_queue_name = component.karpenter.karpenter_interruption_queue_name
    helm_release_status     = component.karpenter.karpenter_helm_release_status
    node_class_name         = component.karpenter.karpenter_node_class_name
    node_pool_name          = component.karpenter.karpenter_node_pool_name
    # node_pool_gpu_name      = component.karpenter.karpenter_node_pool_gpu_name
    node_class_status = component.karpenter.karpenter_node_class_status
  }
}

# --- External DNS Outputs ---
output "external_dns_metadata" {
  description = "Output of External DNS configuration and resources"
  type = object({
    iam_role_arn           = string
    namespace              = string
    service_account_name   = string
    helm_release_name      = string
    helm_release_namespace = string
    helm_release_status    = string
    helm_chart_version     = string
  })
  value = {
    iam_role_arn           = component.addons.external_dns_iam_role_arn
    namespace              = component.addons.external_dns_namespace
    service_account_name   = component.addons.external_dns_service_account_name
    helm_release_name      = component.addons.external_dns_helm_release_name
    helm_release_namespace = component.addons.external_dns_helm_release_namespace
    helm_release_status    = component.addons.external_dns_helm_release_status
    helm_chart_version     = component.addons.external_dns_helm_chart_version
  }
}

# --- Public S3 Bucket ---
output "s3_public_metadata" {
  description = "Output of S3 bucket"
  type = object({
    name = string
    arn  = string
  })
  value = {
    name = component.s3_bucket.public_bucket_name
    arn  = component.s3_bucket.public_bucket_arn
  }
}

# --- RDS Output ---
output "database_metadata" {
  description = "Output of RDS database configuration and resources"
  type = object({
    endpoint         = string
    address          = string
    port             = number
    instance_id      = string
    k8s_service_fqdn = string
    k8s_namespace    = string
  })
  value = {
    endpoint         = component.database.db_endpoint
    address          = component.database.db_address
    port             = component.database.db_port
    instance_id      = component.database.db_instance_id
    k8s_service_fqdn = component.database.k8s_db_service
    k8s_namespace    = component.database.db_namespace
  }
}

# --- Grafana Metadata ---
output "grafana_metadata" {
  description = "Output of Grafana configuration and resources"
  type = object({
    namespace               = string
    admin_secret_name       = string
    values_secret_name      = string
    iam_role_arn            = string
    cloudwatch_policy_arn   = string
    db_password_secret_arn  = string
    oauth_client_secret_arn = string
  })
  value = {
    namespace               = component.grafana.grafana_namespace
    admin_secret_name       = component.grafana.grafana_admin_secret_name
    values_secret_name      = component.grafana.grafana_values_secret_name
    iam_role_arn            = component.grafana.grafana_iam_role_arn
    cloudwatch_policy_arn   = component.grafana.grafana_cloudwatch_policy_arn
    db_password_secret_arn  = component.grafana.grafana_db_password_secret_arn
    oauth_client_secret_arn = component.grafana.grafana_oauth_client_secret_arn
  }
}

# --- STAC Outputs ---
output "stac_metadata" {
  description = "Output of STAC configuration and resources"
  type = object({
    namespace            = string
    write_secret_arn     = string
    read_secret_arn      = string
    read_k8s_secret_name = string
  })
  value = {
    namespace            = component.odc-stac.stac_namespace
    write_secret_arn     = component.odc-stac.stac_write_secret_arn
    read_secret_arn      = component.odc-stac.stac_read_secret_arn
    read_k8s_secret_name = component.odc-stac.stacread_k8s_secret_name
  }
}

# --- ODC Outputs ---
output "odc_metadata" {
  description = "Output of ODC configuration and resources"
  type = object({
    namespace                 = string
    write_password_secret_arn = string
    read_password_secret_arn  = string
    data_reader_role_arn      = string
  })
  value = {
    namespace                 = component.odc.odc_namespace
    write_password_secret_arn = component.odc.odc_write_password_secret_arn
    read_password_secret_arn  = component.odc.odc_read_password_secret_arn
    data_reader_role_arn      = component.odc.odc_data_reader_role_arn
  }
}

# --- Argo Workflow Outputs ---
output "argo_workflow_metadata" {
  description = "Output of Argo Workflow configuration and resources"
  type = object({
    artifact_bucket_name          = string
    namespace                     = string
    artifact_iam_role_arn         = string
    artifact_service_account_name = string
    artifact_iam_policy_arn       = string
    db_password_secret_arn        = string
    k8s_secret_name               = string
    user_artifact_policy_arn      = string
    user_artifact_role_name       = string
    user_artifact_role_arn        = string
    user_name                     = string
  })
  value = {
    artifact_bucket_name          = component.argo-workflow.argo_artifact_bucket_name
    namespace                     = component.argo-workflow.argo_workflow_namespace
    artifact_iam_role_arn         = component.argo-workflow.argo_artifact_iam_role_arn
    artifact_service_account_name = component.argo-workflow.argo_artifact_service_account_name
    artifact_iam_policy_arn       = component.argo-workflow.argo_artifact_iam_policy_arn
    db_password_secret_arn        = component.argo-workflow.argo_db_password_secret_arn
    k8s_secret_name               = component.argo-workflow.argo_k8s_secret_name
    user_artifact_policy_arn      = component.argo-workflow.argo_artifact_policy_arn_for_user
    user_artifact_role_name       = component.argo-workflow.argo_artifact_role_name_for_user
    user_artifact_role_arn        = component.argo-workflow.argo_artifact_role_arn_for_user
    user_name                     = component.argo-workflow.argo_artifact_user_name
  }
}

# --- Flux Outputs ---
output "flux_metadata" {
  description = "Output of Flux configuration and resources"
  type = object({
    namespace           = string
    webhook_secret_name = string
  })
  value = {
    namespace           = component.addons.flux_namespace
    webhook_secret_name = component.addons.slack_webhook_secret_name
  }
}

# --- Terria Outputs ---
output "terria_metadata" {
  description = "Output of Terria configuration and resources"
  type = object({
    bucket_name     = string
    iam_user_name   = string
    k8s_secret_name = string
    k8s_namespace   = string
  })
  value = {
    bucket_name     = component.terria.bucket_name
    iam_user_name   = component.terria.iam_user_name
    k8s_secret_name = component.terria.k8s_secret_name
    k8s_namespace   = component.terria.k8s_namespace
  }
}
