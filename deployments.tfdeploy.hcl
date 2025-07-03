locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Owner"     = "Piksel-Devops-Team"
  }
  region  = "ap-southeast-3"
  project = "Piksel"
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# --- Deployment for Dev Account ---
deployment "development" {
  inputs = {
    # --- General Setup ---
    aws_region   = local.region
    project      = local.project
    environment  = "Dev"
    default_tags = merge(local.common_tags, { "Environment" = "Development" })
    aws_role     = "arn:aws:iam::236122835646:role/stacks-piksel-ina-piksel-ina"
    aws_token    = identity_token.aws.jwt
    # --- Network Setup ---
    vpc_cidr               = "10.1.0.0/16"
    vpc_cidr_shared        = "10.0.0.0/16"
    az_count               = "2"
    single_nat_gateway     = true
    one_nat_gateway_per_az = false
    enable_flow_log        = true
    private_zone_ids = {
      "piksel.internal" = upstream_input.shared.zone_ids["piksel.internal"]
    }
    transit_gateway_id            = upstream_input.shared.transit_gateway_id
    inbound_resolver_ip_addresses = upstream_input.shared.inbound_resolver_ips
    # --- EKS Cluster Setup ---
    cluster_name       = "piksel-dev"
    eks-version        = "1.32"
    coredns-version    = "v1.11.4-eksbuild.2"
    vpc-cni-version    = "v1.19.2-eksbuild.1"
    kube-proxy-version = "v1.32.0-eksbuild.2"
    sso-admin-role-arn = "arn:aws:iam::236122835646:role/aws-reserved/sso.amazonaws.com/ap-southeast-3/AWSReservedSSO_AdministratorAccess_1e048c7b0fa4b3a8"
    # --- External DNS Setup ---
    subdomains                        = ["dev.pik-sel.id"]
    externaldns_crossaccount_role_arn = upstream_input.shared.externaldns_crossaccount_role_arns["dev"]
    public_hosted_zone_id             = upstream_input.shared.zone_ids["dev.pik-sel.id"]
    # --- Karpenter Setup ---
    default_nodepool_node_limit = 500
    default_nodepool_ami_alias  = "al2023@v20250505"
    gpu_nodepool_node_limit     = 5
    gpu_nodepool_ami            = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
    # --- Database Setup ---
    db_instance_class       = "db.t3.small"
    db_allocated_storage    = 50
    backup_retention_period = 14
    # --- Application Setup ---
    oauth_tenant                         = "ap-southeast-3zfzkrhjdu.auth.ap-southeast-3.amazoncognito.com"
    odc_cloudfront_crossaccount_role_arn = upstream_input.shared.odc_cloudfront_crossaccount_role_arns["dev"]
    read_external_buckets = [
      "usgs-landsat",
      "copernicus-dem-30m",
      "e84-earth-search-sentinel-data"
    ]
  }
}

# --- Auto-approve plans for dev ---
orchestrate "auto_approve" "safe_plan_dev" {
  check {
    condition = context.plan.deployment == deployment.development
    reason    = "Only automatically approved plans that are for the dev deployment."
  }
  check {
    condition = context.success
    reason    = "Operation unsuccessful. Check HCP Terraform UI for error details."
  }
  check {
    condition = context.plan.changes.remove == 0
    reason    = "Plan is destroying ${context.plan.changes.remove} resources."
  }
}
