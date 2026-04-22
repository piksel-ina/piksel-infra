terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  cluster = var.cluster_name
  tags    = var.default_tags
  critical_addons_taint = {
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }
  controller_node_selector = {
    "karpenter.sh/controller" = "true"
  }
}

# --- Namespaces ---

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "gpu_operator" {
  metadata {
    name = "gpu-operator"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }
}

# --- cert-manager ---

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      installCRDs  = true
      nodeSelector = local.controller_node_selector
      tolerations  = [local.critical_addons_taint]
      webhook = {
        nodeSelector = local.controller_node_selector
        tolerations  = [local.critical_addons_taint]
      }
      cainjector = {
        nodeSelector = local.controller_node_selector
        tolerations  = [local.critical_addons_taint]
      }
    })
  ]
}

# --- ingress-nginx ---

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.ingress_nginx_chart_version

  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        minAvailable = 1
        resources = {
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }
        service = {
          type = "LoadBalancer"
        }
        allowSnippetAnnotations    = true
        compute-full-forwarded-for = "true"
        forwarded-for-header       = "X-Forwarded-For"
        use-forwarded-headers      = "true"
        config = {
          annotations-risk-level = "Critical"
        }
        nodeSelector = local.controller_node_selector
        tolerations  = [local.critical_addons_taint]
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100
              podAffinityTerm = {
                labelSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name"      = "ingress-nginx"
                    "app.kubernetes.io/component" = "controller"
                  }
                }
                topologyKey = "topology.kubernetes.io/zone"
              }
            }]
          }
        }
      }
      admissionWebhooks = {
        enabled = false
      }
    })
  ]
}

# --- metrics-server ---

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = var.metrics_server_chart_version
  create_namespace = false

  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      args = [
        "--cert-dir=/tmp",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
        "--kubelet-use-node-status-port",
        "--metric-resolution=15s"
      ]
      resources = {
        requests = {
          cpu    = "100m"
          memory = "200Mi"
        }
        limits = {
          cpu    = "300m"
          memory = "400Mi"
        }
      }
      priorityClassName = "system-cluster-critical"
      nodeSelector      = local.controller_node_selector
      tolerations       = [local.critical_addons_taint]
    })
  ]
}

# --- nvidia-device-plugin ---

resource "helm_release" "nvidia_device_plugin" {
  name       = "nvidia-device-plugin"
  namespace  = kubernetes_namespace.gpu_operator.metadata[0].name
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = var.nvidia_device_plugin_chart_version

  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      nodeSelector = {
        "karpenter.k8s.aws/instance-gpu-manufacturer" = "nvidia"
      }
    })
  ]
}

# --- aws-efs-csi-driver ---

resource "helm_release" "aws_efs_csi_driver" {
  name             = "aws-efs-csi-driver"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart            = "aws-efs-csi-driver"
  version          = var.efs_csi_chart_version
  create_namespace = false

  wait            = true
  wait_for_jobs   = true
  timeout         = 300
  cleanup_on_fail = true

  values = [
    yamlencode({
      controller = {
        serviceAccount = {
          create = true
          name   = "efs-csi-controller-sa"
          annotations = {
            "eks.amazonaws.com/role-arn" = var.efs_csi_irsa_role_arn
          }
        }
        tolerations = [
          local.critical_addons_taint
        ]
      }
      node = {
        tolerations = [
          local.critical_addons_taint,
          {
            operator = "Exists"
          }
        ]
        serviceAccount = {
          create = true
          name   = "efs-csi-node-sa"
        }
      }
    })
  ]
}
