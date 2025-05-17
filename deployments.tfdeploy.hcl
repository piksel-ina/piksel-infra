locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Service"   = "piksel.big.go.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  region             = "ap-southeast-3"
  project            = "Piksel"
  transit_gateway_id = "tgw-01f241c653629b467"
  vpc_cidr_shared    = "10.0.0.0/16"
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# --- Deployment for Dev Account ---
deployment "development" {
  inputs = {
    aws_region             = local.region
    project                = local.project
    environment            = "Dev"
    default_tags           = merge(local.common_tags, { "Environment" = "Development" })
    aws_role               = "arn:aws:iam::236122835646:role/stacks-piksel-ina-piksel-ina"
    aws_token              = identity_token.aws.jwt
    vpc_cidr               = "10.1.0.0/16"
    az_count               = "2"
    single_nat_gateway     = true
    one_nat_gateway_per_az = false
    enable_flow_log        = false
    cluster_name           = "piksel-dev-eks-cluster"
    zone_ids               = { "piksel.internal" = "Z069042630870O1I2Q797" }
    transit_gateway_id     = local.transit_gateway_id
    vpc_cidr_shared        = local.vpc_cidr_shared
  }
}

# --- Auto-approve plans for shared and dev---
orchestrate "auto_approve" "safe_plan_dev" {
  check {
    condition = context.plan.deployment == deployment.development
    reason    = "Only automatically approved plans that are for the shared or dev deployment."
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
