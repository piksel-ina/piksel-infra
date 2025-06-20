# --- IAM Policy Documents ---
// Allow ExternalDNS to assume a cross-account role for managing Route53 records
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "AssumeExternalDNSCrossAccountRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      var.externaldns_crossaccount_role_arn
    ]
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
  version    = "1.17.0"

  # Ensure proper dependency order
  depends_on = [
    kubernetes_namespace.external_dns,
    aws_iam_role_policy.external_dns
  ]

  values = [
    yamlencode({
      # Logging configuration
      logLevel  = "debug"
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

      # Use extraArgs to explicitly pass the assume role parameter
      extraArgs = {
        "aws-assume-role"             = var.externaldns_crossaccount_role_arn
        "aws-assume-role-external-id" = "external-dns-${lower(var.environment)}"
        "aws-zone-id-filter"          = var.public_hosted_zone_id
      }

      # Environment variables for AWS
      env = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        }
      ]

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

  timeout           = 600
  wait              = true
  wait_for_jobs     = true
  cleanup_on_fail   = true
  atomic            = true  # Rollback on failure
  create_namespace  = false # We create namespace separately
  dependency_update = true  # Update dependencies
  disable_webhooks  = false
  replace           = false # Don't replace on conflict
  reset_values      = false # Keep existing values
  reuse_values      = false # Don't reuse values from previous install
  skip_crds         = false
  verify            = false # Skip signature verification for speed

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to these to prevent unnecessary updates
      metadata,
      repository_password,
      repository_username,
    ]
  }
}

# --- Flux CD Configuration ---
locals {
  flux_namespace      = "flux-system"
  webhook_secret_name = "flux-notification-slack-webhook-secret-${lower(var.environment)}"
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
    name      = "slack-webhook-${lower(var.environment)}"
    namespace = kubernetes_namespace.flux_system.metadata[0].name
  }
  data = {
    "address" = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
  }
}
