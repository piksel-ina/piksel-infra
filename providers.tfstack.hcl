required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.95"
  }
  tls = {
    source  = "hashicorp/tls"
    version = ">= 4.0"
  }
  time = {
    source  = "hashicorp/time"
    version = ">= 0.9"
  }
  cloudinit = {
    source  = "hashicorp/cloudinit"
    version = ">= 2.0"
  }
  null = {
    source  = "hashicorp/null"
    version = ">= 3.0"
  }
}

provider "aws" "configurations" {
  config {
    region = var.aws_region
    assume_role_with_web_identity {
      role_arn           = var.aws_role
      web_identity_token = var.aws_token
    }
    default_tags {
      tags = var.default_tags
    }
  }
}

provider "tls" "this" {}
provider "time" "this" {}
provider "cloudinit" "this" {}
provider "null" "this" {}
