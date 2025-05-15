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
    environment = var.environment
    project     = var.project
    vpc_id      = component.vpc.vpc_id
    zone_ids    = var.zone_ids
  }

  providers = {
    aws = provider.aws.configurations
  }

}
