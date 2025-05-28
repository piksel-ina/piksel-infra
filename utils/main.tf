# --- Get authorization to pull karpenter Images ---
data "aws_ecrpublic_authorization_token" "token" {}
