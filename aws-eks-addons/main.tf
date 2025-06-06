# --- IAM Policy Documents ---
// allows ExternalDNS to change records only in specific hosted zones
// allows listing all zones and records
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "ChangeResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      for zone_id in values(var.zone_ids) :
      "arn:${var.aws_partition}:route53:::hostedzone/${zone_id}"
    ]
  }

  statement {
    sid    = "ListResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

# --- IAM Role for IRSA (AssumeRole to Cross-Account) ---
resource "aws_iam_role" "external_dns" {
  name = "external-dns-irsa"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider, "https://", "")}:sub" = "system:serviceaccount:aws-external-dns-helm:external-dns"
            "${replace(var.oidc_provider, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name      = "external-dns-irsa"
    Component = "external-dns"
  })
}

# --- Attach the policy document to the IRSA role ---
resource "aws_iam_role_policy" "external_dns" {
  name   = "external-dns-policy"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}

# --- Assume the cross-account role // created at Shared Account ---
resource "aws_iam_role_policy" "external_dns_assume_crossaccount" {
  name = "external-dns-assume-crossaccount"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.externaldns_crossaccount_role_arn
      }
    ]
  })
}

# --- Create Namespace ---
resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "aws-external-dns-helm"

    labels = {
      name      = "aws-external-dns-helm"
      component = "external-dns"
    }
  }
}

# --- Deploy ExternalDNS via Helm release (Let Helm manage the service account) ---
resource "helm_release" "external_dns" {
  name       = "aws-ext-dns-helm"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.14.3"

  # Ensure proper dependency order
  depends_on = [
    kubernetes_namespace.external_dns,
    aws_iam_role_policy.external_dns,
    aws_iam_role_policy.external_dns_assume_crossaccount
  ]

  values = [
    yamlencode({
      # Logging configuration
      logLevel  = "error"
      logFormat = "json"

      # Provider configuration
      provider = {
        name = "aws"
      }

      # DNS configuration
      registry                = "txt"
      txtOwnerId              = "eks-cluster-${var.cluster_name}"
      txtPrefix               = "external-dns"
      policy                  = "sync"
      domainFilters           = var.subdomains
      publishInternalServices = true
      triggerLoopOnEvent      = true
      interval                = "30s"

      # Service Account configuration
      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
        labels = {
          app       = "external-dns"
          component = "external-dns"
        }
      }

      # Pod configuration
      podLabels = {
        app       = "external-dns"
        component = "external-dns"
      }

      podAnnotations = {
        "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
      }

      # AWS specific configuration
      aws = {
        region          = var.aws_region
        assumeRoleArn   = var.externaldns_crossaccount_role_arn
        batchChangeSize = 1000
      }

      # Resource limits for better stability
      resources = {
        limits = {
          memory = "256Mi"
          cpu    = "200m"
        }
        requests = {
          memory = "128Mi"
          cpu    = "100m"
        }
      }
    })
  ]

  timeout         = 300
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  # Handle upgrades gracefully
  force_update  = false
  recreate_pods = false
}

# --- Flux CD Configuration ---
locals {
  flux_namespace      = "flux-system"
  webhook_secret_name = "flux-notification-slack-webhook-secret"
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
}

# --- Fetch Slack Webhook URL from AWS Secrets Manager, created using AWS CLI ---
data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = local.webhook_secret_name
}

resource "kubernetes_secret" "slack_webhook" {
  metadata {
    name      = "slack-webhook"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }
  data = {
    "address" = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
  }
}
