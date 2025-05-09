terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.95"
    }
  }

  cloud {
    organization = "piksel-ina"

    workspaces {
      name = "piksel-infra-dev"
    }
  }
}

provider "aws" {
  alias  = "dev-account"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CrossAccountRoute53Role"
  }
}
