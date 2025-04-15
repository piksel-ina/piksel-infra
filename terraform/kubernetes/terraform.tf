terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "piksel-ina"

    workspaces {
      name = "piksel-kubernetes-dev" # Change this for each component/environment
    }
  }
}
