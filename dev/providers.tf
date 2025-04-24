terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "piksel-ina"

    workspaces {
      name = "piksel-infra-dev"
    }
  }
}
