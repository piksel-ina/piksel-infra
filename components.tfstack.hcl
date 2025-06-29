component "network" {
  source = "./network"

  inputs = {
    region                        = var.aws_region
    project                       = var.project
    environment                   = var.environment
    vpc_cidr                      = var.vpc_cidr
    az_count                      = var.az_count
    single_nat_gateway            = var.single_nat_gateway
    one_nat_gateway_per_az        = var.one_nat_gateway_per_az
    enable_flow_log               = var.enable_flow_log
    flow_log_retention_days       = var.flow_log_retention_days
    cluster_name                  = var.cluster_name
    private_zone_ids              = var.private_zone_ids
    inbound_resolver_ip_addresses = var.inbound_resolver_ip_addresses
    vpc_cidr_shared               = var.vpc_cidr_shared
    transit_gateway_id            = var.transit_gateway_id
    default_tags                  = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }
}

component "eks-cluster" {
  source = "./aws-eks-cluster"

  inputs = {
    cluster_name        = var.cluster_name
    vpc_id              = component.network.vpc_id
    private_subnets_ids = component.network.private_subnets
    eks-version         = var.eks-version
    coredns-version     = var.coredns-version
    vpc-cni-version     = var.vpc-cni-version
    kube-proxy-version  = var.kube-proxy-version
    sso-admin-role-arn  = var.sso-admin-role-arn
    default_tags        = var.default_tags
  }

  providers = {
    aws       = provider.aws.configurations
    tls       = provider.tls.this
    time      = provider.time.this
    null      = provider.null.this
    cloudinit = provider.cloudinit.this
  }

  depends_on = [component.network]
}

component "external-dns" {
  source = "./external-dns"

  inputs = {
    aws_region                        = var.aws_region
    project                           = var.project
    environment                       = var.environment
    cluster_name                      = var.cluster_name
    subdomains                        = var.subdomains
    oidc_provider                     = component.eks-cluster.cluster_oidc_issuer_url
    oidc_provider_arn                 = component.eks-cluster.cluster_oidc_provider_arn
    externaldns_crossaccount_role_arn = var.externaldns_crossaccount_role_arn
    public_hosted_zone_id             = var.public_hosted_zone_id
    default_tags                      = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    helm       = provider.helm.configurations
    kubernetes = provider.kubernetes.configurations
  }

}

component "karpenter" {
  source = "./karpenter"

  inputs = {
    cluster_name                = var.cluster_name
    oidc_provider_arn           = component.eks-cluster.cluster_oidc_provider_arn
    cluster_endpoint            = component.eks-cluster.cluster_endpoint
    default_nodepool_ami_alias  = var.default_nodepool_ami_alias
    default_nodepool_node_limit = var.default_nodepool_node_limit
    gpu_nodepool_ami            = var.gpu_nodepool_ami
    gpu_nodepool_node_limit     = var.gpu_nodepool_node_limit
    default_tags                = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    helm       = provider.helm.configurations
    kubernetes = provider.kubernetes.configurations
  }
}

component "s3_bucket" {
  source = "./aws-s3-bucket"

  inputs = {
    project      = var.project
    environment  = var.environment
    default_tags = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
  }
}

component "database" {
  source = "./aws-database"

  inputs = {
    project                 = var.project
    environment             = var.environment
    vpc_id                  = component.network.vpc_id
    vpc_cidr_block          = component.network.vpc_cidr_block
    private_subnets_ids     = component.network.private_subnets
    cluster_name            = component.eks-cluster.cluster_name
    default_tags            = var.default_tags
    db_instance_class       = var.db_instance_class
    db_allocated_storage    = var.db_allocated_storage
    backup_retention_period = var.backup_retention_period
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "applications" {
  source = "./applications"

  inputs = {
    account_id                           = component.network.account_id
    project                              = var.project
    environment                          = var.environment
    cluster_name                         = component.eks-cluster.cluster_name
    default_tags                         = var.default_tags
    eks_oidc_provider_arn                = component.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url                      = component.eks-cluster.cluster_oidc_issuer_url
    k8s_db_service                       = component.database.k8s_db_service
    subdomains                           = var.subdomains
    public_hosted_zone_id                = var.public_hosted_zone_id
    auth0_tenant                         = var.auth0_tenant
    internal_buckets                     = [component.s3_bucket.public_bucket_name]
    read_external_buckets                = var.read_external_buckets
    odc_cloudfront_crossaccount_role_arn = var.odc_cloudfront_crossaccount_role_arn
  }

  providers = {
    aws               = provider.aws.configurations
    kubernetes        = provider.kubernetes.configurations
    random            = provider.random.this
    aws.virginia      = provider.aws.virginia
    aws.cross_account = provider.aws.cross_account
    postgresql        = provider.postgresql.configurations
  }
}
