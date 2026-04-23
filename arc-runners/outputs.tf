output "namespace" {
  description = "Kubernetes namespace where ARC is deployed"
  value       = kubernetes_namespace.arc.metadata[0].name
}

output "runner_name" {
  description = "Runner scale set name for use in workflow runs-on labels"
  value       = var.runner_name
}

output "runner_role_arn" {
  description = "IAM role ARN assumed by runner pods via EKS Pod Identity"
  value       = aws_iam_role.arc_runner.arn
}

output "runner_service_account" {
  description = "Kubernetes service account name for runner pods"
  value       = kubernetes_service_account.arc_runner.metadata[0].name
}

output "controller_release_status" {
  description = "Status of the ARC controller Helm release"
  value       = helm_release.arc_controller.status
}

output "runner_set_release_status" {
  description = "Status of the ARC runner scale set Helm release"
  value       = helm_release.arc_runner_set.status
}
