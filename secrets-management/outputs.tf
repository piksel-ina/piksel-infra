output "environment" {
  description = "Current environment (workspace)"
  value       = terraform.workspace
}

output "slack_secret_arns" {
  description = "ARNs of created Slack secrets"
  value = {
    for k, v in aws_secretsmanager_secret.slack_secrets : k => v.arn
  }
}

output "oauth_secret_arns" {
  description = "ARNs of created OAuth secrets"
  value = {
    for k, v in aws_secretsmanager_secret.oauth_secrets : k => v.arn
  }
}

output "slack_secret_names" {
  description = "Names of created Slack secrets"
  value = {
    for k, v in aws_secretsmanager_secret.slack_secrets : k => v.name
  }
}

output "oauth_secret_names" {
  description = "Names of created OAuth secrets"
  value = {
    for k, v in aws_secretsmanager_secret.oauth_secrets : k => v.name
  }
}
