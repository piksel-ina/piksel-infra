# Phase 0: AWS Provider v6 + EKS Module v21 Upgrade

## COMPLETED — April 10, 2026

All steps applied and verified. Terraform plan shows `No changes`.

### What Was Done

- AWS Provider upgraded to `>= 6.0, < 7.0` (resolves to v6.40.0)
- EKS Module upgraded to `~> 21.0` — all `cluster_*` prefixes stripped, variable renames applied
- Karpenter Module upgraded to `~> 21.0` — migrated from IRSA to Pod Identity
- `eks-pod-identity-agent` addon added to Terraform (`v1.3.10-eksbuild.2`)
- Node group defaults inlined (v21 removed `eks_managed_node_group_defaults`)
- IMDS hop limit explicitly set to 2
- `enable_inline_policy = true` on Karpenter controller (6,144 char policy limit)
- State imported for pre-existing `eks-pod-identity-agent` addon
- `AmazonEKSVPCResourceController` policy attachment removed by v21 (merged into ClusterPolicy)
- State backed up after apply

---

## Objective

Upgrade the Terraform AWS provider from v5.95 to v6.x and the EKS Terraform module
from v20.33 to v21.x. **EKS version stays at 1.32** — only the provider and module change.

This is the highest-risk phase because it touches all AWS resources across all modules.

---

## Pre-flight Checks

Run these before making any changes:

```bash
make check-health
make check-context
make scan-deprecated
make backup-staging
```

---

## Step 1: Upgrade AWS Provider in staging/providers.tf

### File: `staging/providers.tf`

**Line 5** — Change the AWS provider version constraint:

```diff
- version = "= 5.95"
+ version = ">= 6.0, < 7.0"
```

### AWS Provider v6 Breaking Changes Relevant to This Codebase

Review these carefully — most don't apply but verify:

| Breaking Change | Affected? | Notes |
|---|---|---|
| `aws_eip.vpc` removed → use `domain` | No | Not using EIP directly |
| `aws_eks_addon.resolve_conflicts` removed | No | Handled by EKS module |
| `aws_flow_log.log_group_name` removed | No | Not using flow logs directly |
| `aws_instance.cpu_core_count` removed | No | Using module-managed nodes |
| `aws_ssm_association.instance_id` removed | No | Not used |
| `tags_all` removal on some resources | Maybe | Check if any output references `tags_all` |
| Enhanced region support added | No issue | Backward compatible |

**Action**: None of these breaking changes directly affect your resources. The EKS module
absorbs most of the impact internally.

---

## Step 2: Upgrade EKS Module in aws-eks-cluster/main.tf

### File: `aws-eks-cluster/main.tf`

This is the largest set of changes. The module v21 renames 20+ variables by stripping
the `cluster_` prefix.

**Line 12-13** — Module version:

```diff
- version = "~> 20.33"
+ version = "~> 21.0"
```

**Line 15** — `cluster_name` → `name`:

```diff
- cluster_name                   = local.cluster
+ name                           = local.cluster
```

**Line 16** — `cluster_version` → `kubernetes_version`:

```diff
- cluster_version                = var.eks-version
+ kubernetes_version             = var.eks-version
```

**Line 17** — `cluster_endpoint_public_access` → `endpoint_public_access`:

```diff
- cluster_endpoint_public_access = true
+ endpoint_public_access         = true
```

**Line 20** — `cluster_addons` → `addons`:

```diff
- cluster_addons = {
+ addons = {
```

**Line 48-50** — Add `resolve_conflicts_on_create` explicitly (default changed from
`"OVERWRITE"` to `"NONE"` in v21, which could cause issues with existing addons).
Add to the `aws-ebs-csi-driver` addon block:

```diff
  aws-ebs-csi-driver = {
    addon_version            = var.ebs-csi-version
-   resolve_conflicts        = "OVERWRITE"
+   resolve_conflicts_on_create = "OVERWRITE"
+   resolve_conflicts_on_update = "OVERWRITE"
    service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  }
```

**Line 64** — `cluster_enabled_log_types` → `enabled_log_types`:

```diff
- cluster_enabled_log_types = ["api", "authenticator", "controllerManager", "scheduler"]
+ enabled_log_types         = ["api", "authenticator", "controllerManager", "scheduler"]
```

**Lines 152-162** — `node_security_group_additional_rules` stays the same (not renamed).

**Lines 164-166** — `node_security_group_tags` stays the same (not renamed).

### Default Behavior Changes to Watch

These v21 defaults changed — add explicit overrides if needed:

| Setting | v20 Default | v21 Default | Your Action |
|---|---|---|---|
| IMDS hop limit | 2 | **1** | **Add explicit override to 2** — Karpenter needs IMDS |
| `enable_monitoring` | true | **false** | Add explicit `true` if you want EC2 detailed monitoring |
| `use_latest_ami_release_version` | false | **true** | OK — let it auto-select latest AMI for managed nodes |

**Action for IMDS** — Add to `eks_managed_node_group_defaults` block (after line 71):

```hcl
metadata_options = {
  http_endpoint = "enabled"
  http_tokens   = "required"
  http_put_response_hop_limit = 2
}
```

**Action for monitoring** — Add to `eks_managed_node_group_defaults` if desired:

```hcl
enable_monitoring = true
```

---

## Step 3: Verify EKS Module Outputs in aws-eks-cluster/outputs.tf

### File: `aws-eks-cluster/outputs.tf`

Check that all `module.eks.*` output references are still valid in v21.
The following outputs should still work (not renamed at module root level):

| Output | Reference | Status in v21 |
|---|---|---|
| `cluster_endpoint` | `module.eks.cluster_endpoint` | Still valid |
| `cluster_name` | `module.eks.cluster_name` | Still valid |
| `cluster_certificate_authority_data` | `module.eks.cluster_certificate_authority_data` | Still valid |
| `cluster_oidc_provider_arn` | `module.eks.oidc_provider_arn` | Still valid |
| `cluster_oidc_issuer_url` | `module.eks.cluster_oidc_issuer_url` | Still valid |
| `cluster_tls_certificate_sha1_fingerprint` | `module.eks.cluster_tls_certificate_sha1_fingerprint` | Still valid |
| `authentication_token` | `data.aws_eks_cluster_auth.this.token` | Still valid |

**Also in** `aws-eks-cluster/efs.tf:31` — `module.eks.node_security_group_id` — Still valid.

**Action**: No changes needed in outputs.tf. Verify during plan.

---

## Step 4: Upgrade Karpenter Module in karpenter/main.tf

### File: `karpenter/main.tf`

This is the second-largest change. The Karpenter sub-module in v21 removes IRSA
in favor of EKS Pod Identity.

**Line 20** — Module version:

```diff
- version = "~> 20.33"
+ version = "~> 21.0"
```

**Lines 22-24** — Remove IRSA configuration (these variables no longer exist):

```diff
- enable_irsa            = true
- irsa_oidc_provider_arn = local.oidc_provider
```

Pod Identity is now the default (`create_pod_identity_association = true` by default).
The module will automatically create a Pod Identity association for the Karpenter
controller role.

### Karpenter Helm Release Changes (Lines 122-163)

The Helm release currently configures IRSA via service account annotation.
With Pod Identity, this annotation is **no longer needed** — the association is
managed by the Terraform module.

**Lines 138-145** — Remove the IRSA annotation from Helm values:

```diff
  values = [
    <<-EOT
    settings:
      clusterName: ${local.cluster}
      clusterEndpoint: ${local.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
-   serviceAccount:
-     annotations:
-       eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    controller:
      resources:
```

**Note**: The `module.karpenter.iam_role_arn` output still exists in v21 — it's the
controller IAM role ARN. But the binding mechanism changes from IRSA (annotation)
to Pod Identity (EKS API).

### Verify Karpenter Module Outputs

### File: `karpenter/outputs.tf`

| Output | Reference | Status in v21 |
|---|---|---|
| `karpenter_iam_role_arn` | `module.karpenter.iam_role_arn` | Still valid |
| `karpenter_node_iam_role_name` | `module.karpenter.node_iam_role_name` | Still valid |
| `karpenter_interruption_queue_name` | `module.karpenter.queue_name` | Still valid |

**Action**: No changes needed. Verify during plan.

### Verify NodeClasses Reference

### File: `karpenter/nodeclasses.tf`

All NodeClasses reference `module.karpenter.node_iam_role_name` — this output is
still valid in v21. No changes needed.

---

## Step 5: Check IRSA Modules in aws-eks-cluster/irsa.tf and efs.tf

### Files: `aws-eks-cluster/irsa.tf`, `aws-eks-cluster/efs.tf`

The IRSA modules use `terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks`
at version `5.55.0`. These are separate from the EKS module and **should work with
AWS provider v6** — the IAM module doesn't have a hard dependency on EKS module version.

However, verify:
1. The IAM module v5.55.0 is compatible with AWS provider v6
2. All `oidc_providers` blocks reference `module.eks.oidc_provider_arn` — still valid

**Action**: No changes needed unless plan shows errors. The IRSA approach (used by
EBS CSI, VPC CNI, EFS CSI addons) is independent of the Karpenter
Pod Identity migration. Addon IRSA roles continue to work on EKS 1.32+ with v21.

---

## Step 6: Regenerate Lock File and Init

```bash
# Remove old lock file to allow provider upgrade
rm staging/.terraform.lock.hcl

# Re-initialize with upgraded providers
make init-staging

# Verify the resolved provider versions
grep -A 3 "provider \"registry.terraform.io/hashicorp/aws\"" staging/.terraform.lock.hcl
```

Expected: AWS provider should resolve to v6.40+ (latest as of April 2026).

---

## Step 7: Validate and Plan

```bash
make fmt
make validate-staging
make plan-staging
```

### What to Look For in the Plan

1. **No resource recreation** — The module upgrade should NOT force recreation of
   the EKS cluster, node groups, or IAM roles. The upgrade doc states "No state
   changes required."

2. **Provider version** — Confirm plan shows AWS provider v6.x in the output.

3. **In-place updates** — You may see in-place updates to:
   - EKS cluster resource (provider version bump, no config change)
   - EKS addons (resolve_conflicts parameter change)
   - Managed node groups (IMDS, monitoring default changes if not overridden)
   - IAM policies (no change expected)

4. **Karpenter** — Expect changes to:
   - Karpenter controller IAM role (Pod Identity association created)
   - Helm release (values change — IRSA annotation removed)
   - SQS queue (no change expected)

5. **Warning signs** — Abort and investigate if you see:
   - `forces replacement` on the EKS cluster
   - `forces replacement` on any IAM role used by addons
   - `forces replacement` on VPC, subnet, or security group resources
   - Any `destroy` + `create` pattern on critical resources

### Specific Plan Checks

```bash
# Check for any forces replacement
make plan-staging 2>&1 | grep -i "forces replacement" || echo "No replacements found"

# Check for destroy operations
make plan-staging 2>&1 | grep -E "^.*# .* will be destroyed" || echo "No destroys found"

# Count planned changes
make plan-staging 2>&1 | grep "Plan:"
```

---

## Step 8: Post-Plan Verification (After Apply — NOT YOUR RESPONSIBILITY)

These checks are for whoever runs the apply:

```bash
# Verify cluster is still healthy
make check-health

# Verify Karpenter pods are running
kubectl get pods -n karpenter

# Verify Karpenter Pod Identity association exists
aws eks list-pod-identity-associations --cluster-name piksel-staging

# Verify node groups are ready
kubectl get nodes

# Verify all addons are active
make check-versions

# Backup state after successful apply
make backup-staging
```

---

## Files Changed Summary

| File | Change Type | Description |
|---|---|---|
| `staging/providers.tf:5` | Edit | AWS provider `= 5.95` → `>= 6.0, < 7.0` |
| `aws-eks-cluster/main.tf:12-13` | Edit | Module version `~> 20.33` → `~> 21.0` |
| `aws-eks-cluster/main.tf:15` | Edit | `cluster_name` → `name` |
| `aws-eks-cluster/main.tf:16` | Edit | `cluster_version` → `kubernetes_version` |
| `aws-eks-cluster/main.tf:17` | Edit | `cluster_endpoint_public_access` → `endpoint_public_access` |
| `aws-eks-cluster/main.tf:20` | Edit | `cluster_addons` → `addons` |
| `aws-eks-cluster/main.tf:48-50` | Edit | `resolve_conflicts` → `resolve_conflicts_on_create` + `resolve_conflicts_on_update` |

| `aws-eks-cluster/main.tf:64` | Edit | `cluster_enabled_log_types` → `enabled_log_types` |
| `aws-eks-cluster/main.tf:~71` | Add | `metadata_options` block with hop_limit = 2 |
| `karpenter/main.tf:20` | Edit | Module version `~> 20.33` → `~> 21.0` |
| `karpenter/main.tf:22-24` | Remove | `enable_irsa` and `irsa_oidc_provider_arn` |
| `karpenter/main.tf:144-145` | Remove | `serviceAccount.annotations` from Helm values |
| `staging/.terraform.lock.hcl` | Regenerate | Delete and re-init |

## Files NOT Changed (Verified Safe)

| File | Why No Change |
|---|---|
| `aws-eks-cluster/outputs.tf` | All module output references still valid |
| `aws-eks-cluster/variables.tf` | Internal variable names unchanged |
| `aws-eks-cluster/irsa.tf` | IRSA modules work with provider v6 |
| `aws-eks-cluster/efs.tf` | Same as irsa.tf |

| `karpenter/variables.tf` | Internal variable names unchanged |
| `karpenter/nodeclasses.tf` | `module.karpenter.node_iam_role_name` still valid |
| `karpenter/outputs.tf` | All module output references still valid |
| `staging/main.tf` | EKS version stays at 1.32 in this phase |
| `Makefile` | `EKS_VERSION` stays at 1.32 in this phase |
