module "external_dns_helm" {
  source  = "lablabs/eks-external-dns/aws"
  version = "1.2.1"

  enabled           = true
  argo_enabled      = false
  argo_helm_enabled = false

  cluster_identity_oidc_issuer     = var.oidc_provider
  cluster_identity_oidc_issuer_arn = var.oidc_provider_arn

  namespace                 = "aws-external-dns-helm"
  helm_release_name         = "aws-ext-dns-helm"
  service_account_create    = true
  service_account_name      = "external-dns"
  service_account_namespace = "aws-external-dns-helm"

  irsa_assume_role_enabled = true
  irsa_assume_role_arns    = [var.externaldns_crossaccount_role_arn]

  values = yamlencode({
    LogLevel                = "error"
    provider                = "aws"
    registry                = "txt"
    txtOwnerId              = "eks-cluster"
    txtPrefix               = "external-dns"
    policy                  = "sync"
    domainFilters           = var.subdomains
    publishInternalServices = "true"
    triggerLoopOnEvent      = "true"
    interval                = "5s"
    podLabels = {
      app = "aws-external-dns-helm"
    }
  })

  helm_timeout = 240
  helm_wait    = true
}
