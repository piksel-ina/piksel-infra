# --- Flux CD Configuration ---
locals {
  flux_namespace       = "flux-system"
  slack_webhook_secret = "slack-alerts-${lower(var.environment)}"
}

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = local.flux_namespace
    labels = {
      project     = var.project
      environment = var.environment
      name        = local.flux_namespace
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations
    ]
  }
}

# --- Fetch Slack Webhook URL from AWS Secrets Manager, created using AWS CLI ---
data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = local.slack_webhook_secret
}

resource "kubernetes_secret" "slack_webhook" {
  metadata {
    name      = "slack-webhook-${lower(var.environment)}"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }
  data = {
    "address" = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
  }
}

# --- Flux outputs ---
output "flux_namespace" {
  description = "The namespace where Flux is deployed"
  value       = kubernetes_namespace.flux_system.metadata[0].name
}

output "slack_webhook_secret_name" {
  description = "Slack webhook secret name"
  value       = kubernetes_secret.slack_webhook.metadata[0].name
}
