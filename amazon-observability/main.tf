terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  ci_log_groups = [
    "/aws/containerinsights/${var.cluster_name}/application",
    "/aws/containerinsights/${var.cluster_name}/dataplane",
    "/aws/containerinsights/${var.cluster_name}/host",
    "/aws/containerinsights/${var.cluster_name}/performance",
  ]
}

# --- EKS Control Plane Logs ---
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(var.default_tags, {
    Name      = "${var.cluster_name}-control-plane-logs"
    Service   = "EKS"
    ManagedBy = "Terraform"
  })
}

resource "aws_cloudwatch_log_group" "containerinsights" {
  for_each          = toset(local.ci_log_groups)
  name              = each.value
  retention_in_days = var.cw_log_retention_days
  tags              = var.default_tags
}
