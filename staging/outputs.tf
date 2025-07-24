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
