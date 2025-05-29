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
      for zone_id in var.zone_ids :
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
          }
        }
      }
    ]
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
  }
}

# --- Kubernetes Service Account with IRSA Annotation ---
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "aws-external-dns-helm"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
    labels = {
      "app" = "aws-external-dns-helm"
    }
  }
  automount_service_account_token = true
}

# --- Deploy ExternalDNS via Helm release ---
resource "helm_release" "external_dns" {
  name       = "aws-ext-dns-helm"
  namespace  = kubernetes_namespace.external_dns.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.16.0"

  values = [
    yamlencode({
      logLevel                = "error"
      provider                = "aws"
      registry                = "txt"
      txtOwnerId              = "eks-cluster"
      txtPrefix               = "external-dns"
      policy                  = "sync"
      domainFilters           = var.subdomains
      publishInternalServices = "true"
      triggerLoopOnEvent      = "true"
      interval                = "5s"
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.external_dns.metadata[0].name
      }
      podLabels = {
        app = "aws-external-dns-helm"
      }
      aws = {
        assumeRoleArn = var.externaldns_crossaccount_role_arn
      }
    })
  ]

  timeout = 240
  wait    = true
}
