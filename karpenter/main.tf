locals {
  cluster          = var.cluster_name
  tags             = var.default_tags
  oidc_provider    = var.oidc_provider_arn
  cluster_endpoint = var.cluster_endpoint
}

# --- Karpenter (magic autoscaler) ---
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  enable_irsa            = true
  cluster_name           = local.cluster
  irsa_oidc_provider_arn = local.oidc_provider

  # Node IAM role policies (for EC2 instances)
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    AmazonCNIPolicy              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  # Karpenter controller additional IAM policy statements
  iam_policy_statements = [
    {
      sid       = "CustomAllowRegionalReadActions"
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeSubnets"
      ]
      condition = {
        StringEquals = {
          "aws:RequestedRegion" = "ap-southeast-3"
        }
      }
    },
    {
      sid       = "CustomAllowSSMReadActions"
      effect    = "Allow"
      resources = ["arn:aws:ssm:ap-southeast-3::parameter/aws/service/*"]
      actions   = ["ssm:GetParameter"]
    }
  ]

  tags = local.tags
}

# --- Karpenter Helm Chart with proper wait conditions ---
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  description      = "Karpenter autoscaler for EKS cluster"

  # Ensure Helm waits for all resources including CRDs
  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    <<-EOT
    settings:
      clusterName: ${local.cluster}
      clusterEndpoint: ${local.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    controller:
      resources:
        requests:
          cpu: 1
          memory: 2Gi
        limits:
          cpu: 1
          memory: 2Gi
    EOT
  ]
}

# --- Karpenter AL2023 NodeClass ---
resource "kubernetes_manifest" "karpenter_node_class" {
  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      amiFamily = "AL2023"
      role      = module.karpenter.node_iam_role_name

      amiSelectorTerms = [
        {
          alias = "al2023@v20250505"
        }
      ]

      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "120Gi"
            volumeType = "gp3"
            encrypted  = true
          }
        }
      ]
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.cluster
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = local.cluster
          }
        }
      ]
      tags = merge(local.tags, {
        "karpenter.sh/discovery" = local.cluster
        "AMIFamily"              = "AL2023"
      })
    }
  }
}

# --- Default NodePool ---
resource "kubernetes_manifest" "karpenter_node_pool" {
  depends_on = [kubernetes_manifest.karpenter_node_class]

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r", "t"]
            },
            {
              key      = "karpenter.k8s.aws/instance-cpu"
              operator = "In"
              values   = ["4", "8", "16", "32", "48", "64", "96", "192"]
            },
            {
              key      = "karpenter.k8s.aws/instance-hypervisor"
              operator = "In"
              values   = ["nitro"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["2"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            }
          ]
        }
      }
      limits = {
        cpu = 10000
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
      }
    }
  }
  computed_fields = [
    "spec.template.spec.nodeClassRef",
    "spec.template.spec.requirements",
    "spec.limits",
    "spec.disruption"
  ]
}

#--- GPU Intensive Nodepool --
resource "kubernetes_manifest" "karpenter_node_pool_gpu" {
  depends_on = [kubernetes_manifest.karpenter_node_class]

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "gpu"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["g5.xlarge", "g5.2xlarge", "g5.4xlarge"]
            }
          ]
          taints = [
            {
              key    = "nvidia.com/gpu"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
        }
      }
      limits = {
        gpu = 30
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "Never"
      }
    }
  }
  computed_fields = [
    "spec.template.spec.nodeClassRef",
    "spec.template.spec.requirements",
    "spec.template.spec.taints",
    "spec.limits",
    "spec.disruption"
  ]
}
