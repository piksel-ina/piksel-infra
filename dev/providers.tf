provider "aws" {
  region = var.aws_region
  # allowed_account_ids = tolist(var.allowed_account_ids)
}
