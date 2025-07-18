locals {
  cluster = var.cluster_name
  tags    = var.default_tags
}

# --- IRSA - IAM roles for service accounts ---
module "ebs_csi_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version               = "5.55.0"
  role_name             = "${local.cluster}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "vpc_cni_irsa_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.55.0"
  role_name = "${local.cluster}-vpc-cni"

  # Attach the AWS managed policy
  role_policy_arns = {
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "efs_csi_irsa_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.55.0"
  role_name = "${local.cluster}-efs-csi"

  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }

  tags = local.tags
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
        computeType = "Fargate"
        autoScaling = {
          enabled     = true
          minReplicas = 4
          maxReplicas = 10
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

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profiles = {
    kube_system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
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
