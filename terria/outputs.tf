output "bucket_name" {
  description = "The name of the S3 bucket for Terria."
  value       = aws_s3_bucket.terria_bucket.id
}

output "iam_user_name" {
  description = "The IAM user that can access the bucket."
  value       = aws_iam_user.terria_user.name
}

output "k8s_secret_name" {
  description = "Kubernetes secret containing bucket credentials."
  value       = kubernetes_secret.terria_secret.metadata[0].name
}

output "k8s_namespace" {
  description = "Kubernetes namespace where the secret is stored."
  value       = kubernetes_namespace.terria.metadata[0].name
}
