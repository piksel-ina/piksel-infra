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
    zone_ids                      = var.zone_ids
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

component "data" {
  source = "./utils"
  providers = {
    aws = provider.aws.virginia
  }
}

component "karpenter" {
  source = "./karpenter"

  inputs = {
    cluster_name               = var.cluster_name
    oidc_provider_arn          = component.eks-cluster.cluster_oidc_provider_arn
    cluster_endpoint           = component.eks-cluster.cluster_endpoint
    public_repository_username = component.data.repository_username
    public_repository_passowrd = component.data.repository_password
    default_tags               = var.default_tags
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
    cluster_name                      = var.cluster_name
    subdomains                        = var.subdomains
    oidc_provider                     = component.eks-cluster.cluster_oidc_issuer_url
    oidc_provider_arn                 = component.eks-cluster.cluster_oidc_provider_arn
    externaldns_crossaccount_role_arn = var.externaldns_crossaccount_role_arn
    zone_ids                          = var.zone_ids
    default_tags                      = var.default_tags
  }

  providers = {
    aws        = provider.aws.configurations
    helm       = provider.helm.configurations
    kubernetes = provider.kubernetes.configurations
  }

}
