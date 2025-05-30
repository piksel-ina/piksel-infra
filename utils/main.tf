# --- Get authorization to pull karpenter Images ---
resource "null_resource" "force_refresh" {
  triggers = {
    always_run = timestamp()
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  depends_on = [null_resource.force_refresh]
}
