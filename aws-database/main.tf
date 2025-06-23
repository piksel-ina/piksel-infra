locals {
  tags            = var.default_tags
  private_subnets = var.private_subnets_ids
  cluster_name    = var.cluster_name
  project         = lower(var.project)
  db_username     = replace("${local.project}_${lower(var.environment)}", "/[^a-zA-Z0-9_]/", "")
}

# --- Generates 32-character random password with special characters ---
resource "random_password" "db_random_string" {
  length           = 32
  special          = true
  override_special = "_!%^"
}

# --- Creates a secret in AWS Secrets Manager ---
resource "aws_secretsmanager_secret" "db_password" {
  name        = "database-password"
  description = "Password to access database"

  tags = local.tags
}

# --- Stores the generated password in that secret ---
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_random_string.result
}

# --- Defines a group of private subnets where RDS instance will reside ---
resource "aws_db_subnet_group" "default" {
  name       = "database"
  subnet_ids = local.private_subnets
}

# --- Creates a managed PostgreSQL 16 RDS instance ---
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier                     = "${local.cluster_name}-app-db"
  instance_use_identifier_prefix = true

  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  family               = var.psql_family
  major_engine_version = var.psql_major_engine_version
  instance_class       = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  manage_master_user_password = false
  db_name                     = local.project
  username                    = local.db_username
  password                    = aws_secretsmanager_secret_version.db_password.secret_string
  port                        = 5432

  create_db_subnet_group = true
  subnet_ids             = local.private_subnets

  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = var.backup_retention_period

  # Prevent accidental deletion and re-building
  deletion_protection = true

  tags = local.tags
}

# --- Creates a Kubernetes namespace ---
resource "kubernetes_namespace" "db" {
  metadata {
    name = "database"
  }
}

# --- Allows workloads in cluster to connect to the DB using a K8s service name ---
resource "kubernetes_service" "db_endpoint" {
  metadata {
    name      = "db-endpoint"
    namespace = resource.kubernetes_namespace.db.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = split(":", module.db.db_instance_endpoint)[0]
    port {
      port        = 5432
      target_port = 5432
    }
  }
  wait_for_load_balancer = false
}
