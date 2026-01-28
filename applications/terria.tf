locals {
  terria_namespace       = "terria"
  terria_service_account = "terria-sa"
}

# --- S3 Bucket for TerriaMap sharing ---
resource "aws_s3_bucket" "terria_bucket" {
  bucket = "${local.prefix}-terria-bucket"
  tags   = local.tags
}


# --- Kubernetes Namespace ---
resource "kubernetes_namespace" "terria" {
  metadata {
    name = local.terria_namespace
    labels = {
      project     = var.project
      environment = var.environment
      name        = local.terria_namespace
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels
    ]
  }
}

# --- IAM Policy for S3 Access ---
resource "aws_iam_policy" "terria_s3_policy" {
  name        = "svc-${local.terria_service_account}-policy"
  description = "S3 bucket access policy for TerriaMap sharing feature"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.terria_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.terria_bucket.bucket}/*"
        ]
      },
      {
        # Write
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.terria_bucket.bucket}/*"
        ]
      }
    ]
  })

  tags = local.tags
}

# --- IAM Role for Service Account ---
resource "aws_iam_role" "terria_role" {
  name = "iam-role-for-${local.terria_service_account}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${kubernetes_namespace.terria.metadata[0].name}:${local.terria_service_account}"
            "${replace(var.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# --- Attach Policy to Role ---
resource "aws_iam_role_policy_attachment" "terria_s3_policy_attachment" {
  role       = aws_iam_role.terria_role.name
  policy_arn = aws_iam_policy.terria_s3_policy.arn
}

# --- Kubernetes Service Account with IRSA annotation ---
resource "kubernetes_service_account" "terria" {
  metadata {
    name      = local.terria_service_account
    namespace = kubernetes_namespace.terria.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.terria_role.arn
    }

    labels = {
      project     = var.project
      environment = var.environment
    }
  }
}

# --- Store bucket name as ConfigMap ---
resource "kubernetes_config_map" "terria_config" {
  metadata {
    name      = "terria-config"
    namespace = kubernetes_namespace.terria.metadata[0].name
  }

  data = {
    "bucket-name"   = aws_s3_bucket.terria_bucket.id
    "bucket-region" = aws_s3_bucket.terria_bucket.region
  }
}
