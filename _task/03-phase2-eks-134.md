# Phase 2: EKS Version Upgrade 1.33 → 1.34

## Objective

Upgrade the EKS control plane from Kubernetes 1.33 to 1.34. This phase assumes
Phase 1 (EKS 1.33 upgrade) has been completed and verified.

## Prerequisites

- [ ] Phase 0 applied and verified
- [ ] Phase 1 applied and verified
- [ ] Cluster healthy on 1.33: `make check-health`
- [ ] `kubectl version --short` shows v1.33.x
- [ ] All nodes running v1.33.x
- [ ] State backed up: `make backup-staging`

---

## Step 1: Look Up Compatible Addon Versions for EKS 1.34

```bash
AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --kubernetes-version 1.34 \
  --query 'addons[].{name:addonName, versions:addonVersions[0].addonVersion}' \
  --output table
```

Check each addon individually:

```bash
for addon in vpc-cni coredns kube-proxy aws-ebs-csi-driver; do
  echo "=== $addon ==="
  AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
    --addon-name $addon \
    --kubernetes-version 1.34 \
    --query 'addons[].addonVersions[].addonVersion' \
    --output table
done
```

### Addon Version Guidance

| Addon | Expected Pattern | Notes |
|---|---|---|
| kube-proxy | `v1.34.x-eksbuild.*` | **Must** match K8s 1.34 |
| coredns | `v1.11.x-eksbuild.*` or newer | Minor version bump likely |
| vpc-cni | `v1.19.x-eksbuild.*` or newer | Often K8s-version-independent |
| ebs-csi | `v1.4x.x-eksbuild.*` or newer | Check for latest |

---

## Step 2: Look Up GPU AMI for EKS 1.34

```bash
AWS_PROFILE=staging-piksel aws ssm get-parameter \
  --name /aws/service/eks/optimized-ami/1.34/amazon-linux-2023/amd64/nvidia/recommended/image_id \
  --region ap-southeast-3 \
  --query 'Parameter.Value' --output text
```

Then get the AMI name:

```bash
AWS_PROFILE=staging-piksel aws ec2 describe-images \
  --image-ids <ami-id-from-above> \
  --query 'Images[0].Name' --output text
```

---

## Step 3: Update staging/main.tf

### File: `staging/main.tf`

**Line 63** — EKS version:

```diff
- eks-version            = "1.33"
+ eks-version            = "1.34"
```

**Lines 64-68** — Update all addon versions to 1.34-compatible versions:

```diff
- coredns-version        = "<1.33 version>"
+ coredns-version        = "<LOOK UP FROM STEP 1>"

- vpc-cni-version        = "<1.33 version>"
+ vpc-cni-version        = "<LOOK UP FROM STEP 1>"

- kube-proxy-version     = "v1.33.x-eksbuild.x"
+ kube-proxy-version     = "v1.34.x-eksbuild.x"

- ebs-csi-version        = "<1.33 version>"
+ ebs-csi-version        = "<LOOK UP FROM STEP 1>"


```

**Line 97** — GPU AMI name:

```diff
- gpu_nodepool_ami            = "amazon-eks-node-al2023-x86_64-nvidia-1.33-vXXXXXXXX"
+ gpu_nodepool_ami            = "<LOOK UP FROM STEP 2>"
```

---

## Step 4: Update karpenter/variables.tf Default

### File: `karpenter/variables.tf`

**Line 27** — GPU AMI default:

```diff
- default     = "amazon-eks-node-al2023-x86_64-nvidia-1.33-vXXXXXXXX"
+ default     = "<LOOK UP FROM STEP 2>"
```

---

## Step 5: Update Makefile

### File: `Makefile`

**Line 13**:

```diff
- EKS_VERSION   ?= 1.33
+ EKS_VERSION   ?= 1.34
```

---

## Step 6: Validate and Plan

```bash
make fmt
make validate-staging
make plan-staging
```

### What to Look For

Same as Phase 1, but additionally:

1. **containerd 2.1** — K8s 1.34 ships with containerd 2.1. Verify no container
   runtime issues after upgrade. Check application compatibility.

2. **VolumeAttributesClass GA** — If you use EBS CSI with VolumeAttributesClass,
   note the API migration from `storage.k8s.io/v1beta1` to `storage.k8s.io/v1`.
   The EBS CSI driver handles this transparently for addon-managed installations.

3. **AppArmor deprecation** — Check if any pods use AppArmor profiles:
   ```bash
   kubectl get pods -A -o json | jq -r '.items[] | select(.metadata.annotations["container.apparmor.security.beta.kubernetes.io"] != null) | .metadata.name'
   ```

---

## Step 7: Post-Plan Verification (After Apply — NOT YOUR RESPONSIBILITY)

```bash
# Verify cluster version
kubectl version --short

# Verify nodes
kubectl get nodes -o wide

# Verify addons
make check-versions

# Verify health
make check-health

# Verify all pods
kubectl get pods -A | grep -v Running | grep -v Completed

# Verify Karpenter
kubectl get pods -n karpenter
kubectl get nodepools
kubectl get ec2nodeclasses

# Verify GPU nodes
kubectl get nodes -l nvidia.com/gpu.present=true

# Check endpoints connectivity
make check-endpoints

# Backup state
make backup-staging
```

### EKS 1.34 Specific Checks

1. **containerd 2.1 compatibility** — Run a test pod:
   ```bash
   kubectl run test-ctr --image=public.ecr.aws/amazonlinux/amazonlinux:2023 --rm -it -- /bin/bash
   ```

2. **VolumeAttributesClass** — If used, verify no API errors:
   ```bash
   kubectl get volumeattributesclasses.storage.k8s.io 2>/dev/null || echo "Not using VAC"
   ```

3. **cgroup driver** — If any custom kubelet config sets `--cgroup-driver`,
   plan to remove it (deprecated in 1.34).

---

## Files Changed Summary

| File | Change |
|---|---|
| `staging/main.tf:63` | `eks-version = "1.34"` |
| `staging/main.tf:64` | Updated coredns version |
| `staging/main.tf:65` | Updated vpc-cni version |
| `staging/main.tf:66` | Updated kube-proxy version (must be v1.34.x) |
| `staging/main.tf:67` | Updated ebs-csi version |

| `staging/main.tf:97` | Updated GPU AMI name (1.33 → 1.34) |
| `karpenter/variables.tf:27` | Updated GPU AMI default |
| `Makefile:13` | `EKS_VERSION ?= 1.34` |

## Estimated Downtime

Same as Phase 1: ~15-20 min control plane, rolling node updates.

## Final State After Phase 2

| Component | Version |
|---|---|
| EKS Control Plane | 1.34 (standard support until Dec 2, 2026) |
| AWS Provider | >= 6.0 |
| EKS Module | ~> 21.0 |
| Karpenter | Pod Identity + v1.8.2+ |
| All addons | 1.34-compatible |
