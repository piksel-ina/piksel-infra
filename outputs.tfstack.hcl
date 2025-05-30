# --- Data Source ---
output "account_id" {
  type        = string
  description = "The AWS account ID"
  value       = component.vpc.account_id
}

# --- VPC Outputs ---
output "vpc_id" {
  type        = string
  description = "ID of the VPC"
  value       = component.vpc.vpc_id
}

output "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
  value       = component.vpc.vpc_cidr_block
}

# --- Subnet Outputs ---
output "public_subnets" {
  type        = list(string)
  description = "List of IDs of public subnets"
  value       = component.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of public subnets"
  value       = component.vpc.public_subnets_cidr_blocks
}

output "private_subnets" {
  type        = list(string)
  description = "List of IDs of private subnets"
  value       = component.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks of private subnets"
  value       = component.vpc.private_subnets_cidr_blocks
}

# --- NAT Gateway Outputs ---
output "natgw_ids" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.natgw_ids
}

output "nat_public_ips" {
  type        = list(string)
  description = "List of NAT Gateway IDs"
  value       = component.vpc.nat_public_ips
}

# --- Route Table Outputs ---
output "public_route_table_ids" {
  type        = list(string)
  description = "List of IDs of public route tables"
  value       = component.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  type        = list(string)
  description = "List of IDs of private route tables"
  value       = component.vpc.private_route_table_ids
}

# --- Flow Logs Output ---
output "vpc_flow_log_id" {
  type        = string
  description = "ID of the VPC Flow Log (if enabled)"
  value       = component.vpc.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  type        = string
  description = "ARN of the CloudWatch Log Group for Flow Logs (if enabled)"
  value       = component.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

# --- Route53 Zone Association Outputs ---
output "private_zone_association_id" {
  type        = list(string)
  description = "The account ID of the account that created the hosted zone"
  value       = component.phz_association.private_zone_association_id
}

# --- Transit Gateway Attachment Outputs ---
output "tgw_attachment_arn" {
  description = "The ARN of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_attachment_arn
}

output "tgw_attachment_id" {
  description = "The ID of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_attachment_id
}

output "tgw_vpc_owner_id" {
  description = "The owner ID of the Transit Gateway attachment"
  type        = string
  value       = component.tgw-spoke.tgw_vpc_owner_id

}

# --- Route Table Outputs ---
output "spoke_to_shared_vpc_via_tgw_route_id" {
  description = "The ID of the route to the shared VPC via Transit Gateway"
  type        = list(string)
  value       = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_id
}
output "spoke_to_shared_vpc_via_tgw_route_state" {
  description = "The state of the route to the shared VPC via Transit Gateway"
  type        = list(string)
  value       = component.tgw-spoke.spoke_to_shared_vpc_via_tgw_route_state
}

# --- Security Group Outputs ---
output security_group_metadata {
  description = "Output the security group"
  type = object({
    arn         = string
    id          = string
    name        = string
    description = string
  })
  value = {
    arn         = component.security_group.security_group_arn
    id          = component.security_group.security_group_id
    name        = component.security_group.security_group_name
    description = component.security_group.security_group_description
  }
}

# --- EKS Cluster Outputs ---
output "eks_cluster_metadata" {
  description = "Output of EKS Cluster"
  type = object({
    name                  = string
    endpoint              = string
    certificate_authority = string
    oidc_provider_arn     = string
    oidc_issuer_url       = string
    tls_fingerprint       = string
  })
  value = {
    name                  = component.eks-cluster.cluster_name
    endpoint              = component.eks-cluster.cluster_endpoint
    certificate_authority = component.eks-cluster.cluster_certificate_authority_data
    oidc_provider_arn     = component.eks-cluster.cluster_oidc_provider_arn
    oidc_issuer_url       = component.eks-cluster.cluster_oidc_issuer_url
    tls_fingerprint       = component.eks-cluster.cluster_tls_certificate_sha1_fingerprint
  }
}

# --- Karpenter Outputs ---
output "karpenter_metadata" {
  description = "Output of Karpenter configuration and resources"
  type = object({
    iam_role_arn            = string
    node_iam_role_name      = string
    interruption_queue_name = string
    helm_release_status     = string
    node_class_name         = optional(string)
    node_pool_name          = optional(string)
    # node_pool_gpu_name      = optional(string)
    node_class_status       = optional(map(string))
  })
  value = {
    iam_role_arn            = component.karpenter.karpenter_iam_role_arn
    node_iam_role_name      = component.karpenter.karpenter_node_iam_role_name
    interruption_queue_name = component.karpenter.karpenter_interruption_queue_name
    helm_release_status     = component.karpenter.karpenter_helm_release_status
    node_class_name         = component.karpenter.karpenter_node_class_name
    node_pool_name          = component.karpenter.karpenter_node_pool_name
    # node_pool_gpu_name      = component.karpenter.karpenter_node_pool_gpu_name
    node_class_status       = component.karpenter.karpenter_node_class_status
  }
}

# --- External DNS Outputs ---
output "external_dns_metadata" {
  description = "Output of External DNS configuration and resources"
  type = object({
    iam_role_arn           = string
    namespace              = string
    service_account_name   = string
    helm_release_name      = string
    helm_release_namespace = string
    helm_release_status    = string
    helm_chart_version     = string
  })
  value = {
    iam_role_arn           = component.addons.external_dns_iam_role_arn
    namespace              = component.addons.external_dns_namespace
    service_account_name   = component.addons.external_dns_service_account_name
    helm_release_name      = component.addons.external_dns_helm_release_name
    helm_release_namespace = component.addons.external_dns_helm_release_namespace
    helm_release_status    = component.addons.external_dns_helm_release_status
    helm_chart_version     = component.addons.external_dns_helm_chart_version
  }
}
