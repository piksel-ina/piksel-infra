terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79"
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
  region = var.aws_region
}
