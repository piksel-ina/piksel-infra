resource "kubernetes_namespace" "arc" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" = "arc-runner"
    }
  }
}

# --- ARC Controller ---
resource "helm_release" "arc_controller" {
  name      = "arc-controller"
  chart     = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
  version   = var.controller_chart_version
  namespace = kubernetes_namespace.arc.metadata[0].name

  set {
    name  = "githubAppSecret.githubAppID"
    value = var.github_app_id
  }

  set {
    name  = "githubAppSecret.githubAppInstallationID"
    value = var.github_app_installation_id
  }

  set_sensitive {
    name  = "githubAppSecret.githubAppPrivateKey"
    value = var.github_app_private_key
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "arc-controller-sa"
  }

  timeout         = 300
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.arc]
}

# --- Runner Scale Set ---
resource "helm_release" "arc_runner_set" {
  name      = "arc-runner-set"
  chart     = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
  version   = var.runner_chart_version
  namespace = kubernetes_namespace.arc.metadata[0].name

  set {
    name  = "githubConfigUrl"
    value = "https://github.com/${var.github_org}"
  }

  set {
    name  = "githubConfigSecret.github_app_id"
    value = var.github_app_id
  }

  set {
    name  = "githubConfigSecret.github_app_installation_id"
    value = var.github_app_installation_id
  }

  set_sensitive {
    name  = "githubConfigSecret.github_app_private_key"
    value = var.github_app_private_key
  }

  set {
    name  = "runnerScaleSetName"
    value = var.runner_name
  }

  set {
    name  = "minRunners"
    value = var.min_runners
  }

  set {
    name  = "maxRunners"
    value = var.max_runners
  }

  set {
    name  = "template.spec.containers[0].name"
    value = "runner"
  }

  set {
    name  = "template.spec.containers[0].image"
    value = "ghcr.io/actions/actions-runner:latest"
  }

  set {
    name  = "template.spec.serviceAccountName"
    value = local.runner_sa_name
  }

  timeout         = 300
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  depends_on = [helm_release.arc_controller]
}
