# --- Get authorization to pull karpenter Images ---
data "aws_ecrpublic_authorization_token" "token" {
  region = "us-east-1"
}

# --- Select Ubuntu EKS AMIs Dynamically ---
data "aws_ami" "ubuntu_eks" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_1.32/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

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

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    AmazonCNIPolicy              = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  tags = local.tags
}

# --- Karpenter Helm Chart ---
resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"

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

# --- Karpenter nodeclass and nodepool ---
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2"
      amiSelectorTerms = [{ name = data.aws_ami.ubuntu_eks.id }]
      role = module.karpenter.node_iam_role_name
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "120Gi"
            volumeType = "gp3"
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
      tags = {
        "karpenter.sh/discovery" = local.cluster
      }
    }
  }

  depends_on = [
    helm_release.karpenter
  ]
}

# --- Karpenter default nodepool ---
resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
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
              values   = ["c", "m", "r", "t", "z"]
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

  depends_on = [
    kubernetes_manifest.karpenter_node_class
  ]
}

# --- Karpenter nodepool for GPU instances ---
resource "kubernetes_manifest" "karpenter_node_pool_gpu" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "gpu"
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

  depends_on = [
    kubernetes_manifest.karpenter_node_class
  ]
}
