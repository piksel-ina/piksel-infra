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

output "ubuntu_eks_ami_id" {
  description = "The ID of the latest Ubuntu EKS AMI used for nodes"
  value       = data.aws_ami.ubuntu_eks.id
}

output "karpenter_helm_release_status" {
  description = "The status of the Karpenter Helm release"
  value       = helm_release.karpenter.status
}

output "karpenter_node_class_name" {
  description = "The name of the Karpenter EC2NodeClass"
  value       = yamldecode(kubectl_manifest.karpenter_node_class.yaml_body).metadata.name
}

output "karpenter_node_pool_names" {
  description = "The names of the Karpenter NodePools"
  value = [
    yamldecode(kubectl_manifest.karpenter_node_pool.yaml_body).metadata.name,
    yamldecode(kubectl_manifest.karpenter_node_pool_gpu.yaml_body).metadata.name
  ]
}
