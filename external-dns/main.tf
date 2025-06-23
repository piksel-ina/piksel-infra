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
            "${replace(var.oidc_provider, "https://", "")}:sub" = "system:serviceaccount:external-dns:external-dns-sa"
            "${replace(var.oidc_provider, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "external-dns-irsa"
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
    name = "external-dns"

    labels = {
      name      = "external-dns"
      component = "external-dns"
    }
  }
}

# --- Deploy ExternalDNS via Helm release (Let Helm manage the service account) ---
resource "helm_release" "external_dns" {
  name       = "external-dns-helm"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.17.0"

  depends_on = [
    kubernetes_namespace.external_dns,
    aws_iam_role_policy.external_dns
  ]

  values = [
    yamlencode({
      # Logging configuration
      logLevel  = "info"
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
        name   = "external-dns-sa"
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

      # Use extraArgs for cross-account role assumption
      extraArgs = {
        "aws-assume-role"             = var.externaldns_crossaccount_role_arn
        "aws-assume-role-external-id" = "external-dns-${lower(var.environment)}"
        "zone-id-filter"              = var.public_hosted_zone_id
      }

      # Environment variables for AWS
      env = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        }
      ]

      # Resource limits
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

  # error handling and upgrade management
  timeout         = 300
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  # Handle upgrades gracefully
  force_update  = false
  recreate_pods = false

}
