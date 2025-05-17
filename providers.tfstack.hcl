required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.95"
  }
  local = {
    source  = "hashicorp/local"
    version = "2.5.3"
  }
  tls = {
    source  = "hashicorp/tls"
    version = "4.1.0"
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

provider "local" "this" {}
provider "tls" "this" {}
