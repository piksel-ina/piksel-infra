locals {
  prefix                   = "${lower(var.project)}-${lower(var.environment)}"
  tags                     = var.default_tags
  auth0_client_secret_name = "grafana-auth0-client-secret"
  eks_cluster              = var.cluster_name
}

# --- Creates Kubernetes namespace for monitoring ---
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      project     = var.project
      environment = var.environment
      name        = "monitoring"
      managed-by  = "terraform"
    }
  }
}

# --- Generate secure password for Grafana database connection ---
resource "random_password" "grafana_random_string" {
  length           = 32
  special          = true
  override_special = "_!%^"
}

# --- Store database password in AWS Secrets Manager ---
resource "aws_secretsmanager_secret" "grafana_password" {
  name        = "${local.prefix}-grafana-password"
  description = "Password for Grafana database connection"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "grafana_password" {
  secret_id     = aws_secretsmanager_secret.grafana_password.id
  secret_string = random_password.grafana_random_string.result

}

# --- This secret was issued through AWS CLI ---
data "aws_secretsmanager_secret_version" "grafana_client_secret" {
  secret_id = local.auth0_client_secret_name
}

# --- Generate secure password for Grafana admin user ---
resource "random_bytes" "grafana_admin_password" {
  length = 32
}

# --- Store admin credentials in Kubernetes secret,  ---
# Used for alternative access when OAuth is unavailable
resource "kubernetes_secret" "grafana_admin_credentials" {
  metadata {
    name      = "grafana-admin-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-user     = "grafanasuperuser"
    admin-password = random_bytes.grafana_admin_password.hex
  }

  type = "Opaque"
}

# --- IRSA for CloudWatch access ---
data "aws_iam_policy_document" "grafana_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:monitoring:grafana"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}


# --- Role for Grafana to assume via IRSA  ---
resource "aws_iam_role" "grafana" {
  name               = "${local.eks_cluster}-grafana-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json

  tags = merge({ Name = "${local.eks_cluster}-grafana-role" }, local.tags)
}

# --- Policy statement: cloudWatch read permissions ---
data "aws_iam_policy_document" "grafana_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetInsightRuleReport"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogRecord"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions"
    ]
    resources = ["*"]
  }
}

# --- Create Policy ---
resource "aws_iam_policy" "grafana_cloudwatch" {
  name        = "${local.eks_cluster}-grafana-cloudwatch-policy"
  description = "CloudWatch access for Grafana"
  policy      = data.aws_iam_policy_document.grafana_cloudwatch.json
}

# --- Attach policy to role ---
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_cloudwatch.arn
}

# --- Grafana configuration ---
resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana-values"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "values.yaml" = templatefile("${path.module}/config/grafana.yaml", {
      # IRSA
      service_account_role_arn = aws_iam_role.grafana.arn

      # Auth0
      auth0_tenant  = var.auth0_tenant
      client_id     = split(":", data.aws_secretsmanager_secret_version.grafana_client_secret.secret_string)[0]
      client_secret = split(":", data.aws_secretsmanager_secret_version.grafana_client_secret.secret_string)[1]

      # AWS region for CloudWatch
      aws_region = var.aws_region
    })
  }

  type = "Opaque"
}
