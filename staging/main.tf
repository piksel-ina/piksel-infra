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
  private_subnets_ids = module.networks.private_subnets
  eks-version         = "1.32"
  coredns-version     = "v1.11.4-eksbuild.2"
  vpc-cni-version     = "v1.19.2-eksbuild.1"
  kube-proxy-version  = "v1.32.0-eksbuild.2"
  sso-admin-role-arn  = "arn:aws:iam::326641642924:role/aws-reserved/sso.amazonaws.com/ap-southeast-3/AWSReservedSSO_AdministratorAccess_0e029b26d9443921"
  default_tags        = var.default_tags

  depends_on = [module.networks]
}
