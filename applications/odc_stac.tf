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

# --- Pass Stac read secret to the odc-stac namespace. Writing is done in Argo ---
resource "kubernetes_secret" "stacread_namespace_secret" {
  metadata {
    name      = "stacread-secret"
    namespace = kubernetes_namespace.stac.metadata[0].name
  }
  data = {
    username = "stacread"
    password = var.stac_read_password
  }
  type = "Opaque"
}
