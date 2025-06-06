locals {
  prefix = "${lower(var.project)}-${lower(var.environment)}"
  tags   = var.default_tags
}

# --- Need a bucket and a access and secret key to write to it ---
resource "aws_s3_bucket" "terria_bucket" {
  bucket = "${local.prefix}-terria-bucket"

  tags = local.tags
}

# --- Add IAM User to write to the bucket ---
resource "aws_iam_user" "terria_user" {
  name = "${local.prefix}-terria-user"
  tags = local.tags
}

# --- Create access key for the user ---
resource "aws_iam_access_key" "terria" {
  user = aws_iam_user.terria_user.name
}

# --- Create policy to allow the user to write to the bucket ---
resource "aws_iam_user_policy" "terria_policy" {
  name = "${local.prefix}-terria-policy"
  user = aws_iam_user.terria_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.terria_bucket.arn}",
        "${aws_s3_bucket.terria_bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

# --- Store the access and secret key as a k8s secret ---
resource "kubernetes_namespace" "terria" {
  metadata {
    name = "terria"
  }
}

# --- Store the access and secret key as a Kubernetes secret ---
resource "kubernetes_secret" "terria_secret" {
  metadata {
    name      = "terria-bucket-creds"
    namespace = kubernetes_namespace.terria.metadata[0].name
  }

  data = {
    "bucket-name" = aws_s3_bucket.terria_bucket.id
    "access-key"  = aws_iam_access_key.terria.id
    "secret-key"  = aws_iam_access_key.terria.secret
  }
}
