locals {
  cluster_name = "piksel-staging"
  subdomains   = ["staging.pik-sel.id", "staging.piksel.big.go.id"]
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

  account_id          = module.networks.account_id
  cluster_name        = local.cluster_name
  vpc_id              = module.networks.vpc_id
  vpc_cidr_block      = module.networks.vpc_cidr_block
  private_subnets_ids = module.networks.private_subnets
  eks-version         = "1.32"
  coredns-version     = "v1.11.4-eksbuild.2"
  vpc-cni-version     = "v1.19.2-eksbuild.1"
  kube-proxy-version  = "v1.32.0-eksbuild.2"
  ebs-csi-version     = "v1.46.0-eksbuild.1"
  sso-admin-role-arn  = "arn:aws:iam::326641642924:role/aws-reserved/sso.amazonaws.com/ap-southeast-3/AWSReservedSSO_AdministratorAccess_0e029b26d9443921"
  efs_backup_enabled  = false
  default_tags        = var.default_tags

  depends_on = [module.networks]
}

module "external-dns" {
  source = "../external-dns"

  aws_region                        = var.aws_region
  project                           = var.project
  environment                       = var.environment
  cluster_name                      = local.cluster_name
  subdomains                        = local.subdomains
  oidc_provider                     = module.eks-cluster.cluster_oidc_issuer_url
  oidc_provider_arn                 = module.eks-cluster.cluster_oidc_provider_arn
  externaldns_crossaccount_role_arn = "arn:aws:iam::686410905891:role/externaldns-crossaccount-role-staging"
  default_tags                      = var.default_tags

  depends_on = [module.eks-cluster]
}

module "karpenter" {
  source = "../karpenter"

  cluster_name                = local.cluster_name
  oidc_provider_arn           = module.eks-cluster.cluster_oidc_provider_arn
  cluster_endpoint            = module.eks-cluster.cluster_endpoint
  default_nodepool_ami_alias  = "al2023@v20250505"
  default_nodepool_node_limit = 10000
  gpu_nodepool_ami            = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
  gpu_nodepool_node_limit     = 20
  default_tags                = var.default_tags

  depends_on = [module.eks-cluster]
}

module "s3_bucket" {
  source = "../aws-s3-bucket"

  project      = var.project
  environment  = var.environment
  default_tags = var.default_tags
}


module "database" {
  source = "../aws-database"

  project                 = var.project
  environment             = var.environment
  vpc_id                  = module.networks.vpc_id
  vpc_cidr_block          = module.networks.vpc_cidr_block
  private_subnets_ids     = module.networks.private_subnets
  cluster_name            = module.eks-cluster.cluster_name
  default_tags            = var.default_tags
  db_instance_class       = "db.t4g.medium"
  db_allocated_storage    = 50
  backup_retention_period = 14
  db_multi_az             = false
}

module "applications" {
  source = "../applications"

  account_id                           = module.networks.account_id
  project                              = var.project
  environment                          = var.environment
  cluster_name                         = module.eks-cluster.cluster_name
  default_tags                         = var.default_tags
  eks_oidc_provider_arn                = module.eks-cluster.cluster_oidc_provider_arn
  oidc_issuer_url                      = module.eks-cluster.cluster_oidc_issuer_url
  db_namespace                         = module.database.db_namespace
  db_address                           = module.database.db_address
  k8s_db_service                       = module.database.k8s_db_service
  subdomains                           = local.subdomains
  public_hosted_zone_id                = "Z06367032PXGIV8NRRW3G"
  oauth_tenant                         = "ap-southeast-3zfzkrhjdu.auth.ap-southeast-3.amazoncognito.com"
  internal_buckets                     = [module.s3_bucket.public_bucket_name]
  odc_cloudfront_crossaccount_role_arn = "arn:aws:iam::686410905891:role/odc-cloudfront-crossaccount-role-staging"
  public_bucket_arn                    = module.s3_bucket.public_bucket_arn
  read_external_buckets = [
    "usgs-landsat",
    "copernicus-dem-30m",
    "e84-earth-search-sentinel-data"
  ]
}
