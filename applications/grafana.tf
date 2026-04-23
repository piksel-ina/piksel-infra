locals {
  prefix               = "${lower(var.project)}-${lower(var.environment)}"
  tags                 = var.default_tags
  oauth_secret_grafana = "grafana-oauth-${lower(var.environment)}"
  eks_cluster          = var.cluster_name
  grafana_namespace    = "monitoring"
}

# --- Creates Kubernetes namespace for monitoring ---
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = local.grafana_namespace

    labels = {
      project     = var.project
      environment = var.environment
      name        = local.grafana_namespace
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels
    ]
  }
}

# --- This secret was issued through AWS CLI ---
data "aws_secretsmanager_secret_version" "grafana_client_secret" {
  count     = var.enable_grafana ? 1 : 0
  secret_id = local.oauth_secret_grafana
}

# --- Generate secure password for Grafana admin user ---
resource "random_bytes" "grafana_admin_password" {
  count  = var.enable_grafana ? 1 : 0
  length = 32
}

# --- Store admin credentials in Kubernetes secret,  ---
# Used for alternative access when OAuth is unavailable
resource "kubernetes_secret" "grafana_admin_credentials" {
  count = var.enable_grafana ? 1 : 0

  metadata {
    name      = "grafana-admin-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-user     = "grafanasuperuser"
    admin-password = random_bytes.grafana_admin_password[0].hex
  }

  type = "Opaque"
}

# --- IRSA for CloudWatch access ---
data "aws_iam_policy_document" "grafana_assume_role" {
  count = var.enable_grafana ? 1 : 0

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
  count = var.enable_grafana ? 1 : 0

  name               = "${local.eks_cluster}-grafana-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role[0].json

  tags = merge({ Name = "${local.eks_cluster}-grafana-role" }, local.tags)
}

# --- Policy statement: cloudWatch read permissions ---
data "aws_iam_policy_document" "grafana_cloudwatch" {
  count = var.enable_grafana ? 1 : 0
  #checkov:skip=CKV_AWS_356:CloudWatch/Logs/EC2 read actions require Resource="*". TODO: scope to specific resources when defined.
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
  count = var.enable_grafana ? 1 : 0
  #checkov:skip=CKV_AWS_355:CloudWatch/Logs/EC2 read actions require Resource="*". TODO: scope to specific resources when defined.
  name        = "${local.eks_cluster}-grafana-cloudwatch-policy"
  description = "CloudWatch access for Grafana"
  policy      = data.aws_iam_policy_document.grafana_cloudwatch[0].json
}

# --- Attach policy to role ---
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  count = var.enable_grafana ? 1 : 0

  role       = aws_iam_role.grafana[0].name
  policy_arn = aws_iam_policy.grafana_cloudwatch[0].arn
}

# --- Grafana OAuth Secret for Auth0 Credentials ---
resource "kubernetes_secret" "grafana_oauth" {
  count = var.enable_grafana ? 1 : 0

  metadata {
    name      = "grafana-oauth-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    client_id     = split(":", data.aws_secretsmanager_secret_version.grafana_client_secret[0].secret_string)[0]
    client_secret = split(":", data.aws_secretsmanager_secret_version.grafana_client_secret[0].secret_string)[1]
  }

  type = "Opaque"
}


resource "kubernetes_secret" "grafana" {
  count = var.enable_grafana ? 1 : 0

  metadata {
    name      = "grafana-values"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "values.yaml" = templatefile("${path.module}/config/grafana.yaml", {
      service_account_role_arn = aws_iam_role.grafana[0].arn

      oauth_tenant = var.oauth_tenant

      grafana_subdomain = "grafana.${var.subdomains[0]}"

      aws_region = var.aws_region
    })
  }

  type = "Opaque"
}
