resource "aws_security_group" "codebuild" {
  name_prefix = "${var.project}-tf-codebuild-"
  description = "Security group for Terraform CodeBuild project"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "${var.project}-tf-codebuild"
  })
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project}-tf-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  tags = merge(var.default_tags, {
    Name = "${var.project}-tf-codebuild"
  })
}

resource "aws_iam_policy" "codebuild" {
  name = "${var.project}-tf-codebuild-policy"

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
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/codebuild/*"]
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project}-tf-codebuild-policy"
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

resource "aws_codebuild_project" "plan" {
  name         = "${var.project}-tf-plan"
  description  = "Terraform plan for ${var.environment}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VERSION"
      value = var.terraform_version
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_ACTION"
      value = "plan"
    }

    environment_variable {
      name  = "PLAN_OUTPUT_BUCKET"
      value = var.plan_output_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  vpc_config {
    security_group_ids = [aws_security_group.codebuild.id]
    subnets            = var.private_subnet_ids
    vpc_id             = var.vpc_id
  }

  tags = merge(var.default_tags, {
    Name = "${var.project}-tf-plan"
  })
}

resource "aws_codebuild_project" "apply" {
  name         = "${var.project}-tf-apply"
  description  = "Terraform apply for ${var.environment}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VERSION"
      value = var.terraform_version
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "TF_ACTION"
      value = "apply"
    }

    environment_variable {
      name  = "PLAN_OUTPUT_BUCKET"
      value = var.plan_output_bucket
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  vpc_config {
    security_group_ids = [aws_security_group.codebuild.id]
    subnets            = var.private_subnet_ids
    vpc_id             = var.vpc_id
  }

  tags = merge(var.default_tags, {
    Name = "${var.project}-tf-apply"
  })
}
