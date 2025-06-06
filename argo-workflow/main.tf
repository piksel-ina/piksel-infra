locals {
  prefix                   = "${lower(var.project)}-${lower(var.environment)}"
  auth0_client_secret_name = "argo-auth0-client-secret"
  tags                     = var.default_tags
  eks_cluster              = var.cluster_name
  service_account_name     = "${local.prefix}-argo-artifact-read-write-sa"
}

# --- Dedicated namespace for all Argo resources ---
resource "kubernetes_namespace" "argo_workflow" {
  metadata {
    name = "argo-workflow"
    labels = {
      project     = var.project
      environment = var.environment
      name        = "argo-workflow"
      managed-by  = "terraform"
    }
  }
}

# --- Generate random password and store it securely in AWS, for database connection ---
resource "random_password" "argo_random_string" {
  length           = 32
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "argo_password" {
  name        = "${local.prefix}-argo-workflow-password"
  description = "Password for Argo Workflow server"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "argo_password" {
  secret_id     = aws_secretsmanager_secret.argo_password.id
  secret_string = random_password.argo_random_string.result
}

# --- Fetch auth0 client secret from AWS Secrets Manager, was created outside terraform ---
data "aws_secretsmanager_secret_version" "argo_client_secret" {
  secret_id = local.auth0_client_secret_name
}

# --- Create a kubernetes secret with the auth0 client secret ---
resource "kubernetes_secret" "argo_server_sso" {
  metadata {
    name      = "argo-client-secret"
    namespace = kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    client-id     = split(":", data.aws_secretsmanager_secret_version.argo_client_secret.secret_string)[0]
    client-secret = split(":", data.aws_secretsmanager_secret_version.argo_client_secret.secret_string)[1]
  }

  type = "Opaque"
}

# --- Create a bucket, user and access keys for Argo's artifact storage ---
resource "aws_s3_bucket" "argo" {
  bucket = "${local.prefix}-argo-artifacts-dep"
  tags   = local.tags
}

# --- IAM Policy for Read/Write ---
resource "aws_iam_policy" "argo_artifact_read_write_policy" {
  name        = "svc-${local.service_account_name}-policy"
  description = "Bucket reader/writer policy for ${local.service_account_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.argo.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.argo.bucket}/*"
        ]
      },
      {
        # Write
        Action = [
          "S3:PutObject",
          "S3:PutObjectAcl"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.argo.bucket}/*"
        ]
      }
    ]
  })
}

# --- IAM Role for Service Account (IRSA) ---
module "iam_eks_role_bucket" {
  source               = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name            = "svc-${local.service_account_name}-role"
  max_session_duration = var.max_session_duration

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.argo_workflow.metadata[0].name}:${local.service_account_name}"]
    }
  }

  role_policy_arns = {
    ReadWritePolicy = aws_iam_policy.argo_artifact_read_write_policy.arn
  }
}

# --- Kubernetes Service Account ---
resource "kubernetes_service_account" "argo_artifact" {
  metadata {
    name      = local.service_account_name
    namespace = kubernetes_namespace.argo_workflow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_eks_role_bucket.iam_role_arn
    }
  }
  automount_service_account_token = true
}

# --- Kubernetes Role Binding (optional, for Argo namespace) ---
resource "kubernetes_role_binding" "argo_artifact" {
  metadata {
    name      = "${local.service_account_name}-binding"
    namespace = kubernetes_namespace.argo_workflow.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "argo-workflows-workflow"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = kubernetes_namespace.argo_workflow.metadata[0].name
  }
}

# --- Add Argo secret to the namespace ---
resource "kubernetes_secret" "argo_secret" {
  metadata {
    name      = "argo"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "argo"
    password = aws_secretsmanager_secret_version.argo_password.secret_string
  }
  type = "Opaque"
}

# --- Add other service secrets to Argo namespace ---
resource "kubernetes_secret" "jupyterhub_secret" {
  metadata {
    name      = "jupyterhub"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "jupyterhub"
    password = var.jupyterhub_secret
  }
  type = "Opaque"
}

resource "kubernetes_secret" "grafana_secret" {
  metadata {
    name      = "grafana"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "grafana"
    password = var.grafana_secret
  }
  type = "Opaque"
}

resource "kubernetes_secret" "stacread_secret" {
  metadata {
    name      = "stacread"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "stacread"
    password = var.stacread_secret
  }
  type = "Opaque"
}

resource "kubernetes_secret" "stac_secret" {
  metadata {
    name      = "stac"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "stac"
    password = var.stac_secret
  }
  type = "Opaque"
}

resource "kubernetes_secret" "odcread_secret" {
  metadata {
    name      = "odcread"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "odcread"
    password = var.odcread_secret
  }
  type = "Opaque"
}

resource "kubernetes_secret" "odc_secret" {
  metadata {
    name      = "odc"
    namespace = resource.kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    username = "odc"
    password = var.odc_secret
  }
  type = "Opaque"
}

# --- Add IAM user and access keys for Argo artifact storage ---
# --- Need confirmation that this is the right way to do it ---

# --- Create a policy to read/write the bucket ---
resource "aws_iam_policy" "argo_artifact_read_write_policy_more" {
  name        = "${local.prefix}-argo-artifact-read-write-more"
  description = "Policy to read/write Argo artifacts"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ],
        Resource = [
          aws_s3_bucket.argo.arn,
          "${aws_s3_bucket.argo.arn}/*",
        ],
      },
    ],
  })
}

# --- Create a role for the policy ---
resource "aws_iam_role" "argo_artifact_read_write_role_more" {
  name = "${local.prefix}-argo-artifact-read-write-more"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# --- Create a user for the policy ---
resource "aws_iam_user" "argo_artifact_read_write_user" {
  name = "${local.prefix}-argo-artifact-read-write"
}

# --- Attach the policy to the role ---
resource "aws_iam_role_policy_attachment" "argo_artifact_read_write_policy_attachment" {
  role       = aws_iam_role.argo_artifact_read_write_role_more.name
  policy_arn = aws_iam_policy.argo_artifact_read_write_policy_more.arn
}

# --- Attach the policy to the user ---
resource "aws_iam_user_policy_attachment" "argo_artifact_read_write_user_policy_attachment" {
  user       = aws_iam_user.argo_artifact_read_write_user.name
  policy_arn = aws_iam_policy.argo_artifact_read_write_policy_more.arn
}

# --- Create access keys for the user ---
resource "aws_iam_access_key" "argo_artifact_read_write_access_key" {
  user = aws_iam_user.argo_artifact_read_write_user.name
}

# --- Create a secret for the access keys ---
resource "kubernetes_secret" "argo_artifact_read_write" {
  metadata {
    name      = "argo-artifact-read-write"
    namespace = kubernetes_namespace.argo_workflow.metadata[0].name
  }
  data = {
    access-key = aws_iam_access_key.argo_artifact_read_write_access_key.id
    secret-key = aws_iam_access_key.argo_artifact_read_write_access_key.secret
  }
}
