# --- IRSA - IAM roles for service accounts ---
module "ebs_csi_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.55.0"
  role_name             = "${local.cluster}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "vpc_cni_irsa_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.55.0"
  role_name = "${local.cluster}-vpc-cni"

  # Attach the AWS managed policy
  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "cloudwatch_observability_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.55.0"

  role_name = "${local.cluster}-cloudwatch-observability"

  role_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    CloudWatchLogsFullAccess    = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  oidc_providers = {
    ex = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "amazon-cloudwatch:cloudwatch-agent",
        "amazon-cloudwatch:amazon-cloudwatch-observability-controller-manager",
        "amazon-cloudwatch:dcgm-exporter-service-acct",
        "amazon-cloudwatch:neuron-monitor-service-acct"
      ]
    }
  }

  tags = local.tags
}


# --- Policy that allows EKS nodes to assume the cross-account ECR role ---
resource "aws_iam_policy" "assume_ecr_role" {
  name        = "${local.cluster}-assume-ecr-role"
  description = "Policy to assume cross-account ECR role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeECRRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.cross_account_ecr_role_arn
      },
      {
        Sid    = "AllowPullFromAWSEKSECR"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = [
          "arn:aws:ecr:*:296578399912:repository/*",
          "arn:aws:ecr:*:602401143452:repository/*",
          "arn:aws:ecr:*:686410905891:repository/*"
        ]
      }
    ]
  })
}
