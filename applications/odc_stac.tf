locals {
  stac_namespace = "odc-stac"
}

# --- Creates Kubernetes namespace for ODC SpatioTemporal Asset Catalog  ---
resource "kubernetes_namespace" "stac" {
  metadata {
    name = local.stac_namespace
    labels = {
      project     = var.project
      environment = var.environment
      name        = local.stac_namespace
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels
    ]
  }
}

# --- Store database password in AWS Secrets Manager ---
# Password to write
resource "random_password" "stac_write" {
  length           = 32
  special          = true
  override_special = "@#$&*+-="
}

resource "aws_secretsmanager_secret" "stac_write_password" {
  #checkov:skip=CKV_AWS_149:AWS-managed encryption sufficient. Custom KMS CMK to be implemented when further compliance requires it.
  #checkov:skip=CKV2_AWS_57:Terraform-managed password. Rotation via time_rotating to be implemented when CI/CD pipeline is in place.
  name        = "stac-write-password"
  description = "Password for STAC database connection - Write"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "stac_write_password" {
  secret_id     = aws_secretsmanager_secret.stac_write_password.id
  secret_string = random_password.stac_write.result
}

# Password to read
resource "random_password" "stac_read" {
  length           = 32
  special          = true
  override_special = "@#$&*+-="
}

resource "aws_secretsmanager_secret" "stacread_password" {
  #checkov:skip=CKV_AWS_149:AWS-managed encryption sufficient. Custom KMS CMK to be implemented when further compliance requires it.
  #checkov:skip=CKV2_AWS_57:Terraform-managed password. Rotation via time_rotating to be implemented when CI/CD pipeline is in place.
  name        = "stac-read-password"
  description = "Password for STAC database connection - Read"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "stacread_password" {
  secret_id     = aws_secretsmanager_secret.stacread_password.id
  secret_string = random_password.stac_read.result
}

# --- Pass Stac read secret to the odc-stac namespace. Writing is done in Argo ---
resource "kubernetes_secret" "stacread_namespace_secret" {
  metadata {
    name      = "stacread-secret"
    namespace = kubernetes_namespace.stac.metadata[0].name
  }
  data = {
    username = "stacread"
    password = aws_secretsmanager_secret_version.stacread_password.secret_string
  }
  type = "Opaque"
}
