output "account_id" {
  description = "The AWS account ID"
  value       = module.networks.account_id
}

output "network_metadata" {
  description = "Grouped network and connectivity metadata"
  value = {
    vpc = {
      id                               = module.networks.vpc_id
      cidr_block                       = module.networks.vpc_cidr_block
      flow_log_id                      = module.networks.vpc_flow_log_id
      flow_log_cloudwatch_iam_role_arn = module.networks.vpc_flow_log_cloudwatch_iam_role_arn
    }
    subnets = {
      public_ids          = module.networks.public_subnets
      public_cidr_blocks  = module.networks.public_subnets_cidr_blocks
      private_ids         = module.networks.private_subnets
      private_cidr_blocks = module.networks.private_subnets_cidr_blocks
    }
    nat = {
      ids        = module.networks.natgw_ids
      public_ips = module.networks.nat_public_ips
    }
    route_tables = {
      public_ids  = module.networks.public_route_table_ids
      private_ids = module.networks.private_route_table_ids
    }
  }
}

output "eks_cluster_metadata" {
  description = "Output of EKS Cluster"
  value = {
    name              = module.eks-cluster.cluster_name
    endpoint          = module.eks-cluster.cluster_endpoint
    oidc_provider_arn = module.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url   = module.eks-cluster.cluster_oidc_issuer_url
  }
}

output "external_dns_metadata" {
  description = "Output of External DNS configuration and resources"
  value = {
    iam_role_arn           = module.external-dns.external_dns_iam_role_arn
    namespace              = module.external-dns.external_dns_namespace
    service_account_name   = module.external-dns.external_dns_service_account_name
    helm_release_name      = module.external-dns.external_dns_helm_release_name
    helm_release_namespace = module.external-dns.external_dns_helm_release_namespace
    helm_release_status    = module.external-dns.external_dns_helm_release_status
    helm_chart_version     = module.external-dns.external_dns_helm_chart_version
  }
}

# --- Karpenter Outputs ---
output "karpenter_metadata" {
  description = "Output of Karpenter configuration and resources"
  value = {
    iam_role_arn            = module.karpenter.karpenter_iam_role_arn
    node_iam_role_name      = module.karpenter.karpenter_node_iam_role_name
    interruption_queue_name = module.karpenter.karpenter_interruption_queue_name
    helm_release_status     = module.karpenter.karpenter_helm_release_status
    node_class_status       = module.karpenter.karpenter_node_class_status
    node_pool_name          = module.karpenter.karpenter_node_pool_name
    node_class_gpu_status   = module.karpenter.karpenter_node_class_gpu_status
    node_pool_gpu_name      = module.karpenter.karpenter_node_pool_gpu_name
  }
}

# --- Public S3 Bucket ---
output "s3_public_metadata" {
  description = "Output of S3 bucket"
  value = {
    name = module.s3_bucket.public_bucket_name
    arn  = module.s3_bucket.public_bucket_arn
  }
}

# --- Database outputs ---
output "database_metadata" {
  description = "Output of RDS database configuration and resources"

  value = {
    endpoint         = module.database.db_endpoint
    address          = module.database.db_address
    port             = module.database.db_port
    instance_id      = module.database.db_instance_id
    k8s_service_fqdn = module.database.k8s_db_service
    k8s_namespace    = module.database.db_namespace
    database_name    = module.database.db_name
    db_username      = module.database.db_username
    security_group = {
      arn         = module.database.security_group_arn_database
      id          = module.database.security_group_id_database
      name        = module.database.security_group_name_database
      description = module.database.security_group_description_database
    }
  }
}


# --- Grafana Metadata ---
output "grafana_metadata" {
  description = "Output of Grafana configuration and resources"
  value = {
    namespace               = module.applications.grafana_namespace
    admin_secret_name       = module.applications.grafana_admin_secret_name
    values_secret_name      = module.applications.grafana_values_secret_name
    iam_role_arn            = module.applications.grafana_iam_role_arn
    cloudwatch_policy_arn   = module.applications.grafana_cloudwatch_policy_arn
    db_password_secret_arn  = module.applications.grafana_db_password_secret_arn
    oauth_client_secret_arn = module.applications.grafana_oauth_client_secret_arn
  }
}

# --- JupyterHub Outputs ---
output "jupyterhub_metadata" {
  description = "Output of JupyterHub configuration and resources"
  value = {
    namespace            = module.applications.jupyterhub_namespace
    subdomain            = module.applications.jupyterhub_subdomain
    db_secret_arn        = module.applications.jupyterhub_db_secret_arn
    irsa_role_arn        = module.applications.jupyterhub_irsa_arn
    service_account_name = module.applications.jupyterhub_service_account_name
  }
}

# # --- Flux Outputs ---
# output "flux_metadata" {
#   description = "Output of Flux configuration and resources"
#   type = object({
#     namespace           = string
#     webhook_secret_name = string
#     webhook_secret_arn  = string
#   })
#   value = {
#     namespace           = module.applications.flux_namespace
#     webhook_secret_name = module.applications.slack_webhook_secret_name
#     webhook_secret_arn  = module.applications.slack_webhook_secret_arn
#   }
# }


# --- ODC Outputs ---
output "odc_metadata" {
  description = "Output of ODC configuration and resources"
  value = {
    namespace                 = module.applications.odc_namespace
    write_password_secret_arn = module.applications.odc_write_password_secret_arn
    read_password_secret_arn  = module.applications.odc_read_password_secret_arn
    data_reader_role_arn      = module.applications.odc_data_reader_role_arn
  }
}

# --- ODC OWS Cache Outputs ---
output "odc_ows_cache_metadata" {
  description = "Output of ODC OWS Cache configuration and resources"
  value = {
    cloudfront_domain_name     = module.applications.ows_cache_cloudfront_domain_name
    cloudfront_distribution_id = module.applications.ows_cache_cloudfront_distribution_id
    certificate_arn            = module.applications.ows_cache_certificate_arn
    dns_record                 = module.applications.ows_cache_dns_record
  }
}

# --- STAC Outputs ---
output "stac_metadata" {
  description = "Output of STAC configuration and resources"
  value = {
    namespace            = module.applications.stac_namespace
    write_secret_arn     = module.applications.stac_write_secret_arn
    read_secret_arn      = module.applications.stac_read_secret_arn
    read_k8s_secret_name = module.applications.stacread_k8s_secret_name
  }
}

# --- Argo Workflow Outputs ---
output "argo_workflow_metadata" {
  description = "Output of Argo Workflow configuration and resources"
  value = {
    artifact_bucket_name   = module.applications.argo_artifact_bucket_name
    namespace              = module.applications.argo_workflow_namespace
    iam_role_arn           = module.applications.argo_artifact_iam_role_arn
    service_account_name   = module.applications.argo_artifact_service_account_name
    iam_policy_arn         = module.applications.argo_artifact_iam_policy_arn
    db_password_secret_arn = module.applications.argo_db_password_secret_arn
    k8s_secret_name        = module.applications.argo_k8s_secret_name
  }
}

# --- Terria Outputs ---
output "terria_metadata" {
  description = "Output of Terria configuration and resources"
  value = {
    bucket_name          = module.applications.terria_bucket_name
    iam_role_arn         = module.applications.terria_iam_role_arn
    iam_role_name        = module.applications.terria_iam_role_name
    namespace            = module.applications.terria_namespace
    service_account_name = module.applications.terria_service_account_name
    configmap_name       = module.applications.terria_configmap_name
  }
}
