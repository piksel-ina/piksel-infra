terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "postgresql" {
  host             = coalesce(var.pg_host, split(":", module.db.db_instance_endpoint)[0])
  port             = var.pg_port
  database         = local.project
  username         = local.db_username
  password         = aws_secretsmanager_secret_version.db_password.secret_string
  sslmode          = "require"
  superuser        = false
  connect_timeout  = 15
  expected_version = "16"
}
