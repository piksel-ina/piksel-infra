# Phase 1: EKS Version Upgrade 1.32 → 1.33

## Objective

Upgrade the EKS control plane from Kubernetes 1.32 to 1.33. This phase assumes
Phase 0 (provider + module upgrade) has been completed successfully.

## Prerequisites

- [ ] Phase 0 applied and verified
- [ ] Cluster healthy: `make check-health`
- [ ] State backed up: `make backup-staging`
- [ ] No pending Terraform changes: `make plan-staging` shows "No changes"

---

## Step 1: Look Up Compatible Addon Versions for EKS 1.33

Before changing any files, determine the correct addon versions:

```bash
AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --kubernetes-version 1.33 \
  --query 'addons[].{name:addonName, versions:addonVersions[0].addonVersion}' \
  --output table
```

Alternatively, check each addon individually:

```bash
AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --addon-name vpc-cni \
  --kubernetes-version 1.33 \
  --query 'addons[].addonVersions[].{version:addonVersion,type:compatibilities[0].clusterVersion}' \
  --output table

AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --addon-name coredns \
  --kubernetes-version 1.33 \
  --query 'addons[].addonVersions[].addonVersion' \
  --output table

AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --addon-name kube-proxy \
  --kubernetes-version 1.33 \
  --query 'addons[].addonVersions[].addonVersion' \
  --output table

AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --addon-name aws-ebs-csi-driver \
  --kubernetes-version 1.33 \
  --query 'addons[].addonVersions[].addonVersion' \
  --output table




### Addon Version Guidance

| Addon | Current (1.32) | What to Use for 1.33 | Notes |
|---|---|---|---|
| kube-proxy | `v1.32.0-eksbuild.2` | **Must** be `v1.33.x-eksbuild.*` | Must match K8s minor version |
| coredns | `v1.11.4-eksbuild.2` | Latest compatible for 1.33 | Usually same or minor bump |
| vpc-cni | `v1.19.2-eksbuild.1` | Latest compatible for 1.33 | Often version-independent |
| ebs-csi | `v1.46.0-eksbuild.1` | Latest compatible for 1.33 | Check for newer versions |

**IMPORTANT**: In module v21, `addons.most_recent` defaults to `true`. You can
optionally remove addon version pinning and let the module auto-select the latest
compatible version. This reduces maintenance burden but reduces reproducibility.

### Option A: Keep Pinning (Recommended for First Upgrade)
Look up exact versions and update them in `staging/main.tf`.

### Option B: Remove Pinning (Let Module Auto-Select)
Remove all `*-version` arguments from `staging/main.tf` and the corresponding
variables. The module will auto-select the latest compatible version.

---

## Step 2: Look Up GPU AMI for EKS 1.33

```bash
AWS_PROFILE=staging-piksel aws ssm get-parameter \
  --name /aws/service/eks/optimized-ami/1.33/amazon-linux-2023/amd64/nvidia/recommended/image_id \
  --region ap-southeast-3 \
  --query 'Parameter.Value' --output text
```

Then get the AMI name from the ID:

```bash
AWS_PROFILE=staging-piksel aws ec2 describe-images \
  --image-ids <ami-id-from-above> \
  --query 'Images[0].Name' --output text
```

Expected pattern: `amazon-eks-node-al2023-x86_64-nvidia-1.33-v*`

---

## Step 3: Update staging/main.tf

### File: `staging/main.tf`

**Line 63** — EKS version:

```diff
- eks-version            = "1.32"
+ eks-version            = "1.33"
```

**Line 64** — coredns version (update to latest 1.33-compatible):

```diff
- coredns-version        = "v1.11.4-eksbuild.2"
+ coredns-version        = "<LOOK UP FROM STEP 1>"
```

**Line 65** — vpc-cni version:

```diff
- vpc-cni-version        = "v1.19.2-eksbuild.1"
+ vpc-cni-version        = "<LOOK UP FROM STEP 1>"
```

**Line 66** — kube-proxy version (MUST match 1.33):

```diff
- kube-proxy-version     = "v1.32.0-eksbuild.2"
+ kube-proxy-version     = "v1.33.x-eksbuild.x"
```

**Line 67** — ebs-csi version:

```diff
- ebs-csi-version        = "v1.46.0-eksbuild.1"
+ ebs-csi-version        = "<LOOK UP FROM STEP 1>"
```


**Line 97** — GPU AMI name:

```diff
- gpu_nodepool_ami            = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
+ gpu_nodepool_ami            = "<LOOK UP FROM STEP 2>"
```

### Default AMI Alias (Line 94)

The default nodepool AMI alias `al2023@v20250505` is version-independent — no change needed.
However, you may want to update to a newer alias if available:

```bash
AWS_PROFILE=staging-piksel aws ssm get-parameters-by-path \
  --path "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/amd64/" \
  --recursive \
  --query 'Parameters[].Name'
```

---

## Step 4: Update karpenter/variables.tf Default

### File: `karpenter/variables.tf`

**Line 27** — GPU AMI default (used if not overridden):

```diff
- default     = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
+ default     = "<LOOK UP FROM STEP 2>"
```

This keeps the default in sync, even though `staging/main.tf` explicitly passes the value.

---

## Step 5: Update Makefile

### File: `Makefile`

**Line 13** — EKS version default:

```diff
- EKS_VERSION   ?= 1.32
+ EKS_VERSION   ?= 1.33
```

This affects the `check-ami.sh` and `check-versions.sh` scripts.

---

## Step 6: Validate and Plan

```bash
make fmt
make validate-staging
make plan-staging
```

### What to Look For in the Plan

1. **EKS cluster control plane update** — Should show:
   ```
   module.eks-cluster.module.eks.aws_eks_cluster.this[0] will be updated in-place
   ~ cluster_version = "1.32" -> "1.33"
   ```
   This is the control plane upgrade. It takes ~15-20 minutes.

2. **Addon updates** — Each addon should show a version change:
   ```
   ~ addon_version = "v1.32.0-eksbuild.2" -> "v1.33.x-eksbuild.x"
   ```

3. **Managed node group updates** — After the control plane upgrades, node groups
   will be updated. The module handles this via rolling update. Expect:
   ```
   module.eks-cluster.module.eks.aws_eks_node_group.this["system"] will be updated in-place
   ```

4. **Karpenter GPU AMI** — The `kubectl_manifest` resources for the GPU nodeclass
   will show a diff in the `amiSelectorTerms` field:
   ```
   ~ - name: amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505
   ~ + name: amazon-eks-node-al2023-x86_64-nvidia-1.33-vXXXXXXXX
   ```

5. **Warning signs** — Abort and investigate if:
   - Control plane shows `forces replacement` (should be in-place update)
   - Any addon shows `forces replacement`
   - More than 20 resources changing at once

### Plan Output Analysis

```bash
# Check the plan for the cluster version specifically
make plan-staging 2>&1 | grep "cluster_version"

# Check addon version changes
make plan-staging 2>&1 | grep "addon_version"

# Count total changes
make plan-staging 2>&1 | grep "Plan:"
```

---

## Step 7: Post-Plan Verification (After Apply — NOT YOUR RESPONSIBILITY)

```bash
# Wait for control plane upgrade to complete (~15-20 min)
# Then verify:

# Check cluster version
kubectl version --short

# Check node versions — should eventually show v1.33.x
kubectl get nodes -o wide

# Check addon versions
make check-versions

# Check cluster health
make check-health

# Verify all pods are running
kubectl get pods -A | grep -v Running | grep -v Completed

# Check Karpenter specifically
kubectl get pods -n karpenter
kubectl get nodepools
kubectl get ec2nodeclasses

# Check GPU nodes specifically
kubectl get nodes -l nvidia.com/gpu.present=true

# Backup state
make backup-staging
```

### EKS 1.33 Specific Checks

1. **Endpoints API deprecation** — Check if any workloads use the Endpoints API:
   ```bash
   # Check API call counts
   kubectl get --raw /metrics | grep endpoints_endpoints
   ```

2. **Sidecar containers** — Verify any sidecar containers still work as expected.

3. **DRA beta** — If using GPU scheduling, verify Dynamic Resource Allocation behavior.

---

## Files Changed Summary

| File | Change |
|---|---|
| `staging/main.tf:63` | `eks-version = "1.33"` |
| `staging/main.tf:64` | Updated coredns version |
| `staging/main.tf:65` | Updated vpc-cni version |
| `staging/main.tf:66` | Updated kube-proxy version (must be v1.33.x) |
| `staging/main.tf:67` | Updated ebs-csi version |

| `staging/main.tf:97` | Updated GPU AMI name (1.32 → 1.33) |
| `karpenter/variables.tf:27` | Updated GPU AMI default |
| `Makefile:13` | `EKS_VERSION ?= 1.33` |

## Estimated Downtime

- **Control plane**: ~15-20 minutes (API may be briefly unavailable during failover)
- **Node groups**: Rolling update, one node at a time — zero app downtime if PDBs are set
- **Karpenter nodes**: New nodes will use 1.33 AMI; existing nodes drift until replaced
