component "vpc" {
  source = "./aws-vpc"

  inputs = {
    region                  = var.aws_region
    project                 = var.project
    environment             = var.environment
    vpc_cidr                = var.vpc_cidr
    az_count                = var.az_count
    single_nat_gateway      = var.single_nat_gateway
    one_nat_gateway_per_az  = var.one_nat_gateway_per_az
    enable_flow_log         = var.enable_flow_log
    flow_log_retention_days = var.flow_log_retention_days
    cluster_name            = var.cluster_name
    default_tags            = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }
}

component "phz_association" {
  source = "./aws-route53-za"

  inputs = {
    environment                   = var.environment
    project                       = var.project
    vpc_id                        = component.vpc.vpc_id
    zone_ids                      = var.private_zone_ids
    inbound_resolver_ip_addresses = var.inbound_resolver_ip_addresses
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "tgw-spoke" {
  source = "./aws-tgw-spoke"

  inputs = {
    project                  = var.project
    environment              = var.environment
    vpc_id                   = component.vpc.vpc_id
    vpc_cidr_shared          = var.vpc_cidr_shared
    private_subnet_ids       = component.vpc.private_subnets
    spoke_vpc_route_table_id = component.vpc.private_route_table_ids
    transit_gateway_id       = var.transit_gateway_id
    default_tags             = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }
  depends_on = [component.phz_association]
}

component "security_group" {
  source = "./aws-security-group"

  inputs = {
    vpc_id          = component.vpc.vpc_id
    vpc_cidr_block  = component.vpc.vpc_cidr_block
    vpc_cidr_shared = var.vpc_cidr_shared
    default_tags    = var.default_tags
  }

  providers = {
    aws = provider.aws.configurations
  }

  depends_on = [component.vpc]
}

component "eks-cluster" {
  source = "./aws-eks-cluster"

  inputs = {
    cluster_name        = var.cluster_name
    vpc_id              = component.vpc.vpc_id
    private_subnets_ids = component.vpc.private_subnets
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

  depends_on = [component.vpc]
}

component "karpenter" {
  source = "./karpenter"

  inputs = {
    cluster_name      = var.cluster_name
    oidc_provider_arn = component.eks-cluster.cluster_oidc_provider_arn
    cluster_endpoint  = component.eks-cluster.cluster_endpoint
    default_tags      = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    helm       = provider.helm.configurations
    kubernetes = provider.kubernetes.configurations
  }
}

component "addons" {
  source = "./aws-eks-addons"

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
    zone_ids                          = var.zone_ids
    default_tags                      = var.default_tags
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
    vpc_id                  = component.vpc.vpc_id
    private_subnets_ids     = component.vpc.private_subnets
    cluster_name            = component.eks-cluster.cluster_name
    default_tags            = var.default_tags
    db_instance_class       = var.db_instance_class
    db_allocated_storage    = var.db_allocated_storage
    db_security_group       = [component.security_group.security_group_id_database]
    backup_retention_period = var.backup_retention_period
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "grafana" {
  source = "./grafana"

  inputs = {
    project               = var.project
    environment           = var.environment
    cluster_name          = component.eks-cluster.cluster_name
    default_tags          = var.default_tags
    eks_oidc_provider_arn = component.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url       = component.eks-cluster.cluster_oidc_issuer_url
    auth0_tenant          = var.auth0_tenant
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "jupyterhub" {
  source = "./jupyterhub"

  inputs = {
    project               = var.project
    environment           = var.environment
    cluster_name          = component.eks-cluster.cluster_name
    default_tags          = var.default_tags
    eks_oidc_provider_arn = component.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url       = component.eks-cluster.cluster_oidc_issuer_url
    subdomains            = var.subdomains
    k8s_db_service        = component.database.k8s_db_service
    auth0_tenant          = var.auth0_tenant
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "odc-stac" {
  source = "./odc-stac"

  inputs = {
    project      = var.project
    environment  = var.environment
    default_tags = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "odc" {
  source = "./odc"

  inputs = {
    account_id                           = component.vpc.account_id
    project                              = var.project
    environment                          = var.environment
    default_tags                         = var.default_tags
    eks_oidc_provider_arn                = component.eks-cluster.cluster_oidc_provider_arn
    subdomains                           = var.subdomains
    public_hosted_zone_id                = var.public_hosted_zone_id
    internal_buckets                     = [component.s3_bucket.public_bucket_name]
    read_external_buckets                = var.read_external_buckets
    odc_cloudfront_crossaccount_role_arn = var.odc_cloudfront_crossaccount_role_arn
  }

  providers = {
    aws               = provider.aws.configurations
    aws.virginia      = provider.aws.virginia
    aws.cross_account = provider.aws.cross_account
    kubernetes        = provider.kubernetes.configurations
    random            = provider.random.this
  }
}

component "argo-workflow" {
  source = "./argo-workflow"

  inputs = {
    project               = var.project
    environment           = var.environment
    cluster_name          = var.cluster_name
    default_tags          = var.default_tags
    eks_oidc_provider_arn = component.eks-cluster.cluster_oidc_provider_arn
    jupyterhub_secret     = component.jupyterhub.jupyterhub_db_password
    grafana_secret        = component.grafana.grafana_db_password
    stacread_secret       = component.odc-stac.stac_read_db_password
    stac_secret           = component.odc-stac.stac_write_db_password
    odc_secret            = component.odc.odc_write_db_password
    odcread_secret        = component.odc.odc_read_db_password
  }

  providers = {
    aws        = provider.aws.configurations
    kubernetes = provider.kubernetes.configurations
    random     = provider.random.this
  }
}

component "terria" {
  source = "./terria"

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
