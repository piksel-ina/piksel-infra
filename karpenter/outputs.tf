output "karpenter_iam_role_arn" {
  description = "The ARN of the Karpenter IAM role"
  value       = module.karpenter.iam_role_arn
}

output "karpenter_node_iam_role_name" {
  description = "The name of the Karpenter node IAM role"
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_interruption_queue_name" {
  description = "The name of the Karpenter interruption SQS queue"
  value       = module.karpenter.queue_name
}

output "karpenter_helm_release_status" {
  description = "The status of the Karpenter Helm release"
  value       = helm_release.karpenter.status
}

output "karpenter_node_class_status" {
  description = "Status of the Karpenter EC2NodeClass."
  value       = try(yamldecode(kubectl_manifest.karpenter_node_class.live_manifest_incluster).status, null)
}

output "karpenter_node_pool_name" {
  description = "The name of the default Karpenter NodePool."
  value       = try(yamldecode(kubectl_manifest.karpenter_node_pool.live_manifest_incluster).metadata.name, null)
}

output "karpenter_node_class_gpu_status" {
  description = "Status of the Karpenter GPU NodePool."
  value       = try(yamldecode(kubectl_manifest.karpenter_node_pool_gpu.live_manifest_incluster).status, null)
}

output "karpenter_node_pool_gpu_name" {
  description = "The name of the GPU Karpenter NodePool."
  value       = try(yamldecode(kubectl_manifest.karpenter_node_pool_gpu.live_manifest_incluster).metadata.name, null)
}
