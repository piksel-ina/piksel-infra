# Actions Runner Controller (ARC) for EKS

Deploys [GitHub Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller) into the staging EKS cluster. Runners are ephemeral Kubernetes pods, so CI/CD workflows can reach RDS, EKS, and S3 directly from inside the VPC.

## Overview

ARC uses the Autoscaling Runner Scale Sets architecture. A controller pod watches GitHub for queued workflow jobs and scales runner pods accordingly.

What this module creates:

- Kubernetes namespace (`arc-runners`)
- IAM role and policy for IRSA, granting runner pods access to S3, Secrets Manager, ECR, EKS, and RDS
- Kubernetes ServiceAccount with the IRSA role annotation
- ARC controller Helm release (`oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller`)
- Runner scale set Helm release (`oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set`)

## How it works

1. The controller pod authenticates to GitHub using a GitHub App. Credentials are injected via Helm values at deploy time.
2. When a workflow targeting the runner group is triggered, GitHub notifies the controller through a listener.
3. The controller creates an `EphemeralRunnerSet`, which schedules runner pods onto cluster nodes via Karpenter.
4. Runner pods assume the IRSA IAM role for AWS access, execute the job, report results to GitHub, and terminate.
5. When idle, the controller scales runners down to `minRunners` (default: 0).

## Secrets and bootstrap

GitHub App credentials (Client ID, Installation ID, Private Key) go in `staging/secrets.auto.tfvars`, which is gitignored.

```
secrets.auto.tfvars → Terraform variables → Helm set_sensitive values → K8s secrets (managed by Helm)
```

After the first `terraform apply`, the credentials live in the cluster as Kubernetes secrets managed by the Helm releases. The `.auto.tfvars` file is only needed on the operator's machine for future `terraform apply` runs.

## IAM permissions

The runner IAM policy (`{cluster}-arc-runner-policy`) grants:

| Service | Actions | Scope |
|---|---|---|
| S3 | GetObject, PutObject, DeleteObject, ListBucket | TF state bucket only |
| Secrets Manager | GetSecretValue, DescribeSecret | All secrets in account/region |
| ECR | GetAuthorizationToken, full read/write | All repositories (`*`) |
| EKS | DescribeCluster, ListAddons, DescribeAddon | Staging cluster only |
| RDS | DescribeDBInstances | All DB instances in account/region |

## Usage in workflows

Target the runner scale set from any GitHub Actions workflow in the `piksel-ina` org:

```yaml
jobs:
  deploy:
    runs-on: piksel-staging-runners
    steps:
      - run: echo "Running on ARC runner inside EKS"
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
