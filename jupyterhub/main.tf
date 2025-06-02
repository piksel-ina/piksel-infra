locals {
  prefix                   = "${lower(var.project)}-${lower(var.environment)}"
  auth0_client_secret_name = "jupyter-auth0-client-secret"
  tags                     = var.default_tags
  eks_cluster              = var.cluster_name
  jhub_subdomain           = "jupyter.${var.subdomains[0]}" # subdomain list pattern: [public, private]
}

# --- Dedicated namespace for all hub resources ---
resource "kubernetes_namespace" "hub" {
  metadata {
    name = "jupyterhub"
    labels = {
      project     = var.project
      environment = var.environment
      name        = "jupyterhub"
      managed-by  = "terraform"
    }
  }
}


# --- Generate random password and store it securely in AWS ---
resource "random_password" "jupyterhub_random_string" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "jupyterhub_password" {
  name = "${local.prefix}-jupyterhub-password"
}

resource "aws_secretsmanager_secret_version" "jupyterhub_password" {
  secret_id     = aws_secretsmanager_secret.jupyterhub_password.id
  secret_string = random_password.jupyterhub_random_string.result
}

# --- Grab DB Secret into this namespace
resource "kubernetes_secret" "hub_db_secret" {
  metadata {
    name      = "hub-db-secret"
    namespace = kubernetes_namespace.hub.metadata[0].name
  }
  data = {
    username = "jupyterhub"
    password = aws_secretsmanager_secret_version.jupyterhub_password.secret_string
  }
  type = "Opaque"
}

# --- Secret for JupyterHub Helm values ---
# Secret for auth0 was issued from AWS CLI
data "aws_secretsmanager_secret_version" "hub_client_secret" {
  secret_id = local.auth0_client_secret_name
}

# JupyterHub secrets for cookies
resource "random_id" "jhub_hub_cookie_secret_token" {
  byte_length = 32
}

# JupyterHub secrets for cookies proxy
resource "random_id" "jhub_proxy_secret_token" {
  byte_length = 32
}

# JupyterHub secrets for Dask Gateway API token
resource "random_password" "dask_gateway_api_token" {
  length  = 64
  special = false
  upper   = false
}

# --- Combine all secrets into a single config that GitOps can consume ---
resource "kubernetes_secret" "jupyterhub" {
  metadata {
    name      = "jupyterhub"
    namespace = kubernetes_namespace.hub.metadata[0].name
  }

  data = {
    "values.yaml" = templatefile("${path.module}/config/jupyterhub.yaml", {
      region    = var.aws_region
      host_name = var.jhub_subdomain

      # auth
      jhub_auth_client_id     = split(":", data.aws_secretsmanager_secret_version.hub_client_secret.secret_string)[0]
      jhub_auth_client_secret = split(":", data.aws_secretsmanager_secret_version.hub_client_secret.secret_string)[1]

      # Need to strip the https:// off the front and .auth0.com off the back
      auth0_tenant = trimsuffix(trimprefix(var.auth0_tenant, "https://"), ".auth0.com")

      # Jupyterhub hub database
      jhub_db_name     = "jupyterhub"
      jhub_db_username = "jupyterhub"
      jhub_db_password = aws_secretsmanager_secret_version.jupyterhub_password.secret_string
      jhub_db_hostname = "db-endpoint.db.svc.cluster.local"

      # Secrets
      jhub_hub_cookie_secret_token = random_id.jhub_hub_cookie_secret_token.hex
      jhub_proxy_secret_token      = random_id.jhub_proxy_secret_token.hex
      jhub_dask_gateway_api_token  = random_password.dask_gateway_api_token.result
    })
  }

  type = "Opaque"
}

# --- Kubernetes secrets for JupyterHub ---
resource "kubernetes_secret" "hub-dask-token" {
  metadata {
    name      = "hub-dask-token"
    namespace = kubernetes_namespace.hub.metadata[0].name
  }

  data = {
    token = random_password.dask_gateway_api_token.result
  }

  type = "Opaque"
}

# --- Enable Data Access to Landsat with IRSA---
# --- S3 read policy to access Landsat data ---
resource "aws_iam_policy" "hub_user_read_policy" {
  name        = "jupyterhub-user-read-policy"
  description = "IAM policy for JupyterHub users to read USGS Landsat data"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Statement for accessing Landsat data
        Action = [
          "s3:ListBucket",
          "S3:GetBucketLocation",
          "S3:GetObject",
          "S3:GetObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::usgs-landsat",
          "arn:aws:s3:::usgs-landsat/*",
        ]
      },
      {
        # Statement for requester pays access
        Effect = "Allow"
        Action = [
          "s3:GetBucketRequestPayment"
        ]
        Resource = "arn:aws:s3:::usgs-landsat"
      }
    ]
  })
}

# --- IRSA for JupyterHub users ---
module "iam_eks_role_hub_reader" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "svc-hub-user-read"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${kubernetes_namespace.hub.metadata[0].name}:user-read"]
    }
  }

  role_policy_arns = {
    HubUserRead = aws_iam_policy.hub_user_read_policy.arn
  }
}

# --- Create services account ---
resource "kubernetes_service_account" "hub_user_read" {
  metadata {
    name      = "user-read"
    namespace = kubernetes_namespace.hub.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_eks_role_hub_reader.iam_role_arn
    }
  }
  automount_service_account_token = true
}
