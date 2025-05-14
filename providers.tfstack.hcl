required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.95"
  }
}

provider "aws" "configurations" {
  for_each = var.regions

  config {
    region = each.value

    assume_role_with_web_identity {
      role_arn           = var.aws_role
      web_identity_token = var.aws_token
    }

    default_tags {
      tags = var.default_tags
    }
  }
}
