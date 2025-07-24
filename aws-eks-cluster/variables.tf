locals {
  cluster = var.cluster_name
  tags    = var.default_tags
}

variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
  default     = "piksel-eks-cluster"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID value"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block"
  type        = string

}

variable "private_subnets_ids" {
  description = "List of private subnets ID"
  type        = list(string)
}

# --- EKS Specific Variables ---
variable "eks-version" {
  type        = string
  description = "The version of Kubernetes for this environment"
}

variable "coredns-version" {
  type        = string
  description = "The version of CoreDNS for this environment"
}

variable "vpc-cni-version" {
  type        = string
  description = "The version of VPC CNI for this environment"
}

variable "sso-admin-role-arn" {
  type        = string
  description = "The ARN of SSO Admin group"
}

variable "kube-proxy-version" {
  type        = string
  description = "The version of kube-proxy for this environment"
}

variable "ebs-csi-version" {
  type        = string
  description = "The version of EBS CSI driver"
}

variable "efs-csi-version" {
  type        = string
  description = "The version of EFS CSI driver"

}
