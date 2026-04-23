locals {
  runner_sa_name = "arc-runner-sa"
}

resource "aws_iam_role" "arc_runner" {
  name = "${var.cluster_name}-arc-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.cluster_name}-arc-runner"
  })
}

resource "aws_iam_policy" "arc_runner" {
  name = "${var.cluster_name}-arc-runner-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.tf_state_bucket_arn,
          "${var.tf_state_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = ["arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListAddons",
          "eks:DescribeAddon"
        ]
        Resource = ["arn:aws:eks:${var.aws_region}:${var.account_id}:cluster/${var.cluster_name}"]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = ["arn:aws:rds:${var.aws_region}:${var.account_id}:db:*"]
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.cluster_name}-arc-runner-policy"
  })
}

resource "aws_iam_role_policy_attachment" "arc_runner" {
  role       = aws_iam_role.arc_runner.name
  policy_arn = aws_iam_policy.arc_runner.arn
}

resource "kubernetes_service_account" "arc_runner" {
  metadata {
    name      = local.runner_sa_name
    namespace = kubernetes_namespace.arc.metadata[0].name
  }
}

resource "aws_eks_pod_identity_association" "arc_runner" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace.arc.metadata[0].name
  service_account = local.runner_sa_name
  role_arn        = aws_iam_role.arc_runner.arn
}
