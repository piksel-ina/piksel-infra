# Quick Reference: Commands Cheat Sheet

## Pre-Upgrade Baseline

```bash
make check-health        # Confirm cluster is healthy before starting
make check-context       # Verify kubectl context
make check-versions      # Current addon versions baseline
make check-ami           # Current AMI versions baseline
make scan-deprecated     # Deprecated API scan baseline
make backup-staging      # State backup before changes
```

## Per-Phase Cycle

```bash
make fmt                 # Format Terraform files
make validate-staging    # Syntax + type check
make plan-staging        # Review plan before applying
# >>> DO NOT APPLY YOURSELF — hand off for review <<<
make backup-staging      # Back up state after apply
```

## Addon Version Lookup

```bash
# All addons for a specific K8s version
AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --kubernetes-version 1.33 \
  --query 'addons[].{name:addonName, version:addonVersions[0].addonVersion}' \
  --output table

# Specific addon
AWS_PROFILE=staging-piksel aws eks describe-addon-versions \
  --addon-name kube-proxy --kubernetes-version 1.33 \
  --query 'addons[].addonVersions[].addonVersion' --output table
```

## GPU AMI Lookup

```bash
# Get recommended GPU AMI ID
AWS_PROFILE=staging-piksel aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/amd64/nvidia/recommended/image_id" \
  --region ap-southeast-3 --query 'Parameter.Value' --output text

# Get AMI name from ID
AWS_PROFILE=staging-piksel aws ec2 describe-images \
  --image-ids <ami-id> --query 'Images[0].Name' --output text
```

## Post-Upgrade Verification

```bash
kubectl version --short                          # Cluster version
kubectl get nodes -o wide                        # Node versions
make check-health                                # Cluster health
make check-versions                              # Addon versions
make check-endpoints                             # Endpoint connectivity
kubectl get pods -A | grep -v Running | grep -v Completed  # Problem pods
kubectl get pods -n karpenter                    # Karpenter health
```

## Plan Analysis

```bash
# Check for destructive changes
make plan-staging 2>&1 | grep -i "forces replacement" || echo "OK: No replacements"

# Check for destroys
make plan-staging 2>&1 | grep -E "^.*# .* will be destroyed" || echo "OK: No destroys"

# Summary
make plan-staging 2>&1 | grep "Plan:"
```
