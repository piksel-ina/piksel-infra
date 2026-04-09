# Rollback Procedures

## General Rules

- **NEVER run `terraform destroy`**
- State backups are in S3, managed by `backup.sh`
- Each phase should be a separate commit for easy `git revert`
- Restore state with: `cd staging && bash backup.sh get`

---

## Phase 0 Rollback: Provider / Module Downgrade

**If the plan in Phase 0 shows destructive changes, do NOT proceed.**

To roll back the code changes:

```bash
git revert HEAD  # Revert the Phase 0 commit
```

To restore Terraform state (if apply was attempted and partially failed):

```bash
cd staging && bash backup.sh get
# Files land in tf_backup/
# Copy the relevant .tfstate file to staging/terraform.tfstate
```

**Key risk**: If `terraform apply` ran and changed some resources before failing,
the state may be partially updated. Restore from backup and re-run `make plan-staging`
to see what's different.

---

## Phase 1 Rollback: EKS Version 1.33 → 1.32

EKS **does not support version downgrade**. If you need to go back to 1.32:

1. **The cluster cannot be downgraded in-place.** You would need to create a new
   cluster at 1.32 and migrate workloads.
2. **This is extremely disruptive.** The better approach is to fix issues on 1.33.

### Mitigation Instead of Rollback

If issues arise on 1.33:

1. **Addon issues** — Pin addon versions to the 1.32-compatible versions:
   ```bash
   # Update staging/main.tf addon versions back to 1.32-compatible values
   # But keep eks-version = "1.33"
   make plan-staging
   make apply-staging
   ```

2. **Node issues** — Karpenter nodes can be replaced:
   ```bash
   kubectl delete node <problematic-node>
   # Karpenter will provision a replacement
   ```

3. **Application issues** — Use Kubernetes rolling restarts:
   ```bash
   make restart-deployments
   ```

---

## Phase 2 Rollback: EKS Version 1.34 → 1.33

Same constraints as Phase 1 — EKS does not support in-place downgrade.

### Mitigation

Same approach as Phase 1 rollback mitigation.

---

## State Recovery

### From S3 Backup

```bash
cd staging
bash backup.sh get
# The latest backup will be in tf_backup/
ls -la tf_backup/
# Restore the state file
cp tf_backup/terraform.tfstate.backup-YYYYMMDD-HHMMSS terraform.tfstate
```

### Verify Restored State

```bash
make plan-staging
# Should show "No changes" if state matches infrastructure
```

---

## Emergency Contacts / Runbook

| Scenario | Action |
|---|---|
| Plan shows `forces replacement` on cluster | Do NOT apply. Review module upgrade. Check state. |
| Apply fails mid-way | Restore state from backup. Run `make plan-staging`. |
| Nodes not joining after upgrade | Check node security group, IMDS, IAM role. |
| Karpenter pods crashing | Check Pod Identity association. Check IAM role. |
| Addons stuck in `DEGRADED` | Check addon version compatibility. Try `resolve_conflicts_on_update = "OVERWRITE"`. |
| GPU nodes not provisioning | Check GPU AMI name/version. Check NVIDIA device plugin. |
| Applications failing | Check deprecated APIs with `make scan-deprecated`. |
