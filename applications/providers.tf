provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "aws" {
  region = var.aws_region
  alias  = "cross_account"
  assume_role {
    role_arn = "arn:aws:iam::686410905891:role/odc-cloudfront-crossaccount-role-staging"
  }
}
