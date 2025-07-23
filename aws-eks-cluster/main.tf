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
        computeType = "Fargate"
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
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    aws-efs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.efs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_ids

  # --- NEW: EKS Managed Node Groups ---
  eks_managed_node_groups = {
    general = {
      name           = "${local.cluster}-general"
      instance_types = ["t3.medium", "t3.large"]

      min_size     = 1
      max_size     = 2
      desired_size = 2

      # Use the latest EKS Optimized AMI
      ami_type = "AL2023_x86_64_STANDARD"

      capacity_type = "SPOT"

      # Disk configuration
      disk_size = 20
      disk_type = "gp3"

      # Use our custom security group
      vpc_security_group_ids = [aws_security_group.node_group_sg.id]

      tags = merge(local.tags, {
        "karpenter.sh/discovery" = local.cluster
      })
    }
  }

  create_cluster_security_group = true
  create_node_security_group    = true

  fargate_profiles = {
    flux = {
      selectors = [
        { namespace = "flux-system" }
      ]
    }
    external_dns = {
      selectors = [
        { namespace = "external-dns" }
      ]
    }
  }

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

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster
  })
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
