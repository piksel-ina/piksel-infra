output "argo_artifact_bucket_name" {
  description = "The name of the S3 bucket for Argo artifacts."
  value       = aws_s3_bucket.argo.bucket
}

output "argo_workflow_namespace" {
  description = "The namespace for all Argo resources."
  value       = kubernetes_namespace.argo_workflow.metadata[0].name
}

output "argo_artifact_iam_role_arn" {
  description = "The ARN of the IAM role assumed by the Argo artifact service account (IRSA)."
  value       = module.iam_eks_role_bucket.iam_role_arn
}

output "argo_artifact_service_account_name" {
  description = "The name of the Kubernetes service account used by Argo for artifact access."
  value       = kubernetes_service_account.argo_artifact.metadata[0].name
}

output "argo_artifact_iam_policy_arn" {
  description = "The ARN of the IAM policy for S3 read/write access."
  value       = aws_iam_policy.argo_artifact_read_write_policy.arn
}

output "argo_db_password_secret_arn" {
  description = "The ARN of the AWS Secrets Manager secret storing the Argo DB password."
  value       = aws_secretsmanager_secret.argo_password.arn
}

output "argo_k8s_secret_name" {
  description = "The name of the Kubernetes secret containing the Auth0 client secret."
  value       = kubernetes_secret.argo_server_sso.metadata[0].name
}

output "argo_artifact_policy_arn_for_user" {
  description = "The ARN of the policy that allows read/write access to the Argo artifact bucket."
  value       = aws_iam_policy.argo_artifact_read_write_policy_more.arn
}

output "argo_artifact_role_name_for_user" {
  description = "The IAM role name for Argo artifact read/write."
  value       = aws_iam_role.argo_artifact_read_write_role_more.name
}

output "argo_artifact_role_arn_for_user" {
  description = "The IAM role ARN for Argo artifact read/write."
  value       = aws_iam_role.argo_artifact_read_write_role_more.arn
}

output "argo_artifact_user_name" {
  description = "The IAM user name for Argo artifact read/write."
  value       = aws_iam_user.argo_artifact_read_write_user.name
}

output "argo_artifact_k8s_secret_name" {
  description = "Kubernetes secret containing Argo artifact user credentials."
  value       = kubernetes_secret.argo_artifact_read_write.metadata[0].name
}
