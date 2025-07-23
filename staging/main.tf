locals {
  cluster_name = "piksel-staging"
}

module "networks" {
  source = "../networks"

  project      = var.project
  environment  = var.environment
  cluster_name = local.cluster_name
  vpc_cidr     = "10.2.0.0/16"
  az_count     = "2"
  default_tags = var.default_tags

}


module "eks-cluster" {
  source = "../aws-eks-cluster"


  cluster_name        = local.cluster_name
  vpc_id              = module.networks.vpc_id
  vpc_cidr_block      = module.networks.vpc_cidr_block
  private_subnets_ids = component.network.private_subnets
  eks-version         = var.eks-version
  coredns-version     = var.coredns-version
  vpc-cni-version     = var.vpc-cni-version
  kube-proxy-version  = var.kube-proxy-version
  sso-admin-role-arn  = var.sso-admin-role-arn
  default_tags        = var.default_tags



  depends_on = [module.networks]
}
