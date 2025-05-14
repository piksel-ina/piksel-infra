locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Service"   = "piksel.big.go.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  regions = ["ap-southeast-3"]
  project = "Piksel"
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# --- Deployment for Shared Account ---
deployment "shared" {
  inputs = {
    # --- General Configuration ---
    regions      = local.regions
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
    cluster_name            = "piksel-shared-eks-cluster"
  }
}

# --- Deployment for Dev Account ---
deployment "development" {
  inputs = {
    # --- General Configuration ---
    regions      = local.regions
    project      = local.project
    environment  = "Dev"
    default_tags = merge(local.common_tags, { "Environment" = "Development" })
    # --- Authentication ---
    aws_role  = "arn:aws:iam::236122835646:role/stacks-piksel-ina-piksel-ina"
    aws_token = identity_token.aws.jwt
    # --- VPC Configuration ---
    vpc_cidr               = "10.1.0.0/16"
    az_count               = "2"
    single_nat_gateway     = true
    one_nat_gateway_per_az = false
    enable_flow_log        = false
    cluster_name           = "piksel-dev-eks-cluster"
  }
}

# --- Auto-approve plans for shared ---
orchestrate "auto_approve" "shared_env_approval" {
  check {
    condition = context.plan.deployment == deployment.shared && context.success
    reason    = "Operation unsuccessful. Error Summary: ${context.errors.summary}."
  }
}

# --- Auto-approve plans for dev ---
orchestrate "auto_approve" "dev_env_approval" {
  check {
    condition = context.plan.deployment == deployment.development && context.success
    reason    = "Operation unsuccessful. Error Summary: ${context.errors.summary}."
  }
}
