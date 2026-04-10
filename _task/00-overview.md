# EKS Upgrade Plan: 1.32 → 1.33 → 1.34

## Current State

| Component | Version |
|---|---|
| EKS Control Plane | 1.32 (extended support since Mar 23, 2026) |
| Terraform AWS Provider | >= 6.0, < 7.0 (resolves to v6.40.0) |
| terraform-aws-modules/eks/aws | ~> 21.0 |
| Karpenter Helm Chart | 1.8.2 |
| Karpenter Module | ~> 21.0 (Pod Identity) |
| EKS Pod Identity Agent addon | v1.3.10-eksbuild.2 |

## Target State

| Component | Version |
|---|---|
| EKS Control Plane | 1.34 |
| Terraform AWS Provider | >= 6.0 |
| terraform-aws-modules/eks/aws | ~> 21.0 |
| Karpenter Helm Chart | 1.8.2 (or newer if compatible) |
| Karpenter Module | ~> 21.0 |

## Execution Phases

| Phase | What | Risk | Est. Effort | Status |
|---|---|---|---|---|
| **Phase 0** | AWS Provider v6 + EKS Module v21 upgrade | HIGH - breaking changes across all modules | 2-3 days | **DONE** |
| **Phase 1** | EKS version 1.32 → 1.33 | MEDIUM - API deprecations, addon versions | 1 day | Pending |
| **Phase 2** | EKS version 1.33 → 1.34 | LOW - fewer changes from 1.33 | 0.5 day | Pending |

## Urgency

EKS 1.32 entered **extended support on March 23, 2026** — you are currently incurring
extended support charges ($0.10/cluster/hour). Standard support ends; extended support
runs until March 23, 2027.

## Key Risks

1. ~~**AWS Provider v6 is a major breaking change** — affects all AWS resources, not just EKS~~ (resolved)
2. ~~**EKS Module v21 renames many variables** — `cluster_*` prefix stripped from 20+ variables~~ (resolved)
3. ~~**Karpenter migrates from IRSA to Pod Identity** — Helm chart values must change~~ (resolved)
4. ~~**IMDS hop limit changes from 2 to 1** — may break Karpenter pod IMDS access~~ (overridden to 2)
5. **No state migration required** — module v21 upgrade doc confirms "No state changes required"

## Rules of Engagement

- **NEVER run `terraform apply`** — use `make plan-staging` to validate only
- **NEVER run `terraform destroy`** in any environment
- Always run `make fmt` before `make validate-staging`
- Back up state before each phase: `make backup-staging`
- Each phase should be its own PR with plan output attached for review

## Phase 0 Completion Notes

- **Completed**: April 10, 2026
- AWS Provider upgraded to v6.40.0, EKS module to v21, Karpenter module to v21
- Karpenter migrated from IRSA to EKS Pod Identity (addon `eks-pod-identity-agent` added)
- `eks_managed_node_group_defaults` removed — all defaults inlined into each node group
- `desired_size` for systems node group set to 2 (was temporarily raised for rolling update)
- Karpenter Helm release uses `wait = false` / `wait_for_jobs = false` as workaround for chicken-and-egg during initial Pod Identity setup (safe to revert once stable)
- `enable_inline_policy = true` on Karpenter controller (policy exceeds AWS managed policy 6,144 char limit)
- `AmazonEKSVPCResourceController` policy attachment removed by module v21 (now part of `AmazonEKSClusterPolicy`)
- State backed up after apply
- Terraform plan shows `No changes` — infrastructure matches configuration

### Discoveries During Phase 0

1. `eks_managed_node_group_defaults` was REMOVED in v21 — must inline all defaults into each node group
2. `disk_type` was REMOVED in v21 — gp3 is the default for AL2023
3. `taints` changed from list to map in v21
4. `iam_policy_statements[].condition` changed from map to list of objects in Karpenter sub-module v21
5. Karpenter v1.8.4 has a TopologySpreadConstraint regression — stay on 1.8.2
6. Pod Identity association defaults to `kube-system` namespace — must pass `namespace = "karpenter"` explicitly
7. Karpenter Helm chart defaults `automountServiceAccountToken: false` — must set to `true` for Pod Identity
8. `eks-pod-identity-agent` addon was not pre-installed — required for Pod Identity to function

## Kubernetes Version Timeline (from AWS)

| Version | EKS Release | End Standard Support | End Extended Support |
|---|---|---|---|
| 1.32 (current) | Jan 23, 2025 | Mar 23, 2026 | Mar 23, 2027 |
| 1.33 (Phase 1) | May 29, 2025 | Jul 29, 2026 | Jul 29, 2027 |
| 1.34 (Phase 2) | Oct 2, 2025 | Dec 2, 2026 | Dec 2, 2027 |
| 1.35 (latest) | Jan 27, 2026 | Mar 27, 2027 | Mar 27, 2028 |

## Kubernetes Changelog Summary

### 1.33 (Phase 1 target)
- **Sidecar containers GA** (stable)
- **In-Place Pod Resource Resize** promoted to beta
- **Endpoints API deprecated** — migrate to EndpointSlices
- Dynamic Resource Allocation beta API enabled
- No AL2 AMI released (you're on AL2023 — not affected)

### 1.34 (Phase 2 target)
- **containerd updated to 2.1** — test custom containers
- **VolumeAttributesClass GA** — `storage.k8s.io/v1beta1` → `storage.k8s.io/v1`
- **AppArmor deprecated** — migrate to seccomp or Pod Security Standards
- **Dynamic Resource Allocation (DRA) GA** — GPU scheduling improvements
- **Pod-level resource requests/limits** beta
- **cgroup driver manual config deprecated** — auto-detection preferred
