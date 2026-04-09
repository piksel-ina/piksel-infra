# EKS Upgrade Plan: 1.32 → 1.33 → 1.34

## Current State

| Component | Version |
|---|---|
| EKS Control Plane | 1.32 (extended support since Mar 23, 2026) |
| Terraform AWS Provider | = 5.95 |
| terraform-aws-modules/eks/aws | ~> 20.33 |
| Karpenter Helm Chart | 1.8.2 |
| Karpenter Module | ~> 20.33 |

## Target State

| Component | Version |
|---|---|
| EKS Control Plane | 1.34 |
| Terraform AWS Provider | >= 6.0 |
| terraform-aws-modules/eks/aws | ~> 21.0 |
| Karpenter Helm Chart | 1.8.2 (or newer if compatible) |
| Karpenter Module | ~> 21.0 |

## Execution Phases

| Phase | What | Risk | Est. Effort |
|---|---|---|---|
| **Phase 0** | AWS Provider v6 + EKS Module v21 upgrade | HIGH - breaking changes across all modules | 2-3 days |
| **Phase 1** | EKS version 1.32 → 1.33 | MEDIUM - API deprecations, addon versions | 1 day |
| **Phase 2** | EKS version 1.33 → 1.34 | LOW - fewer changes from 1.33 | 0.5 day |

## Urgency

EKS 1.32 entered **extended support on March 23, 2026** — you are currently incurring
extended support charges ($0.10/cluster/hour). Standard support ends; extended support
runs until March 23, 2027.

## Key Risks

1. **AWS Provider v6 is a major breaking change** — affects all AWS resources, not just EKS
2. **EKS Module v21 renames many variables** — `cluster_*` prefix stripped from 20+ variables
3. **Karpenter migrates from IRSA to Pod Identity** — Helm chart values must change
4. **IMDS hop limit changes from 2 to 1** — may break Karpenter pod IMDS access
5. **No state migration required** — module v21 upgrade doc confirms "No state changes required"

## Rules of Engagement

- **NEVER run `terraform apply`** — use `make plan-staging` to validate only
- **NEVER run `terraform destroy`** in any environment
- Always run `make fmt` before `make validate-staging`
- Back up state before each phase: `make backup-staging`
- Each phase should be its own PR with plan output attached for review

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
