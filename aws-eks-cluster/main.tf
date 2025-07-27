locals {
  cluster = var.cluster_name
  tags    = var.default_tags
}

# --- Create Cluster ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.33"

  cluster_name                   = local.cluster
  cluster_version                = var.eks-version
  cluster_endpoint_public_access = true

  # EKS Addons
  cluster_addons = {
    coredns = {
      addon_version = var.coredns-version
      configuration_values = jsonencode({
        autoScaling = {
          enabled     = true
          minReplicas = 3
          maxReplicas = 6
        }
        resources = {
          requests = {
            cpu    = "0.50"
            memory = "256M"
          }
          limits = {
            cpu    = "1.00"
            memory = "512M"
          }
        }
      })
    }
    kube-proxy = {
      addon_version = var.kube-proxy-version
    }
    vpc-cni = {
      addon_version            = var.vpc-cni-version
      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    }
    aws-ebs-csi-driver = {
      addon_version            = var.ebs-csi-version
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_ids

  # --- EKS Managed Node Groups ---
  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = true
    ami_type                   = "AL2023_x86_64_STANDARD"
    disk_size                  = 20
    disk_type                  = "gp3"

    labels = {
      "karpenter.sh/controller" = "true"
    }

    taints = [
      {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
    tags = local.tags
  }

  eks_managed_node_groups = {
    # 1 On-Demand for system reliability
    system = {
      name = "system-v2"

      min_size     = 1
      max_size     = 2
      desired_size = 1

      capacity_type  = "ON_DEMAND"
      instance_types = ["c5.xlarge"]
    }

    # Spot node group for cost savings
    system-spot = {
      name = "system-spot-v1"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      capacity_type  = "SPOT"
      instance_types = ["c5.xlarge", "c5.2xlarge", "m5.large", "t3.large", "t3.xlarge"]
    }
  }

  # Enable cluster access
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    admin-access = {
      kubernetes_groups = []
      principal_arn     = var.sso-admin-role-arn

      policy_associations = {
        single = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Additional Node Security Groups:
  node_security_group_additional_rules = {
    # Allow outbound DNS for External DNS
    egress_dns_tcp = {
      description = "Allow outbound DNS TCP"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  node_security_group_tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster
  })

  tags = local.tags
}


data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
