output "plan_project_name" {
  description = "CodeBuild project name for terraform plan"
  value       = aws_codebuild_project.plan.name
}

output "apply_project_name" {
  description = "CodeBuild project name for terraform apply"
  value       = aws_codebuild_project.apply.name
}

output "codebuild_role_arn" {
  description = "IAM role ARN used by CodeBuild"
  value       = aws_iam_role.codebuild.arn
}
