locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Service"   = "piksel.big.go.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  region  = "ap-southeast-3"
  project = "Piksel"
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# --- Deployment for Shared Account ---
deployment "shared" {
  inputs = {
    # --- General Configuration ---
    aws_region   = local.region
    project      = local.project
    environment  = "Shared"
    default_tags = merge(local.common_tags, { "Environment" = "Shared" })
    # --- Authentication ---
    aws_role  = "arn:aws:iam::686410905891:role/stacks-piksel-ina-piksel-ina"
    aws_token = identity_token.aws.jwt
    # --- VPC Configuration ---
    vpc_cidr                = "10.0.0.0/16"
    az_count                = "3"
    single_nat_gateway      = true
    one_nat_gateway_per_az  = false
    enable_flow_log         = true
    flow_log_retention_days = 30
  }
}

# --- Auto-approve plans for shared and dev---
orchestrate "auto_approve" "safe_plan_shared" {
  check {
    condition = context.plan.deployment == deployment.shared
    reason    = "Only automatically approved plans that are for the shared deployment."
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
