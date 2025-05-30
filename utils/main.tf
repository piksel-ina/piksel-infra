variable "enable_token_refresh" {
  type    = bool
  default = false
}

resource "null_resource" "force_refresh" {
  count = var.enable_token_refresh ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  count      = var.enable_token_refresh ? 1 : 0
  depends_on = [null_resource.force_refresh]
}
