terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get current workspace name for environment-specific naming
locals {
  environment = terraform.workspace
}

# Slack webhook secrets
resource "aws_secretsmanager_secret" "slack_secrets" {
  for_each = var.slack_secrets

  name        = "${each.key}-${local.environment}"
  description = each.value.description

  tags = {
    Project     = each.value.project
    Service     = each.value.service
    Environment = local.environment
    Owner       = "Piksel-Devops-Team"
    Tenant      = each.value.tenant
  }
}

resource "aws_secretsmanager_secret_version" "slack_secrets" {
  for_each = var.slack_secrets

  secret_id     = aws_secretsmanager_secret.slack_secrets[each.key].id
  secret_string = each.value.secret_string
}

# OAuth client secrets (format: client_id:client_secret)
resource "aws_secretsmanager_secret" "oauth_secrets" {
  for_each = var.oauth_secrets

  name        = "${each.key}-${local.environment}"
  description = each.value.description

  tags = {
    Project     = each.value.project
    Service     = each.value.service
    Environment = local.environment
    Owner       = "Piksel-Devops-Team"
    Tenant      = each.value.tenant
  }
}

resource "aws_secretsmanager_secret_version" "oauth_secrets" {
  for_each = var.oauth_secrets

  secret_id     = aws_secretsmanager_secret.oauth_secrets[each.key].id
  secret_string = "${each.value.client_id}:${each.value.client_secret}"
}
