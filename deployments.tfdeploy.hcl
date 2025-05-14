locals {
  common_tags = {
    "ManagedBy" = "Terraform"
    "Project"   = "Piksel"
    "Service"   = "piksel.big.go.id"
    "Owner"     = "Piksel-Devops-Team"
  }
  regions = ["ap-southeast-3"]
}

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

deployment "shared" {
  inputs = {
    regions      = local.regions
    environment  = "Shared"
    aws_role     = "arn:aws:iam::686410905891:role/stacks-piksel-ina-piksel-ina"
    aws_token    = identity_token.aws.jwt
    default_tags = merge(local.common_tags, { "Environment" = "Shared" })
  }
}

deployment "development" {
  inputs = {
    regions      = local.regions
    environment  = "Dev"
    aws_role     = "arn:aws:iam::236122835646:role/stacks-piksel-ina-piksel-ina"
    aws_token    = identity_token.aws.jwt
    default_tags = merge(local.common_tags, { "Environment" = "Development" })
  }
}
