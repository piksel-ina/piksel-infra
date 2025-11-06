## Terraform State Backup

Simple backup script for Terraform state files to S3.

### Usage

**Backup (run after every `terraform apply`):**

```bash
bash backup.sh run
```

**Restore:**

```bash
bash backup.sh get
```

Files will be downloaded to `tf_backedup/` directory.

### Restoring Files

After downloading backup:

1. Review files in `tf_backedup/`
2. Manually move files to Terraform directory
3. **⚠️ Be careful:** Overwriting `terraform.tfstate` with wrong version will cause state desync and mess up infrastructure

### When to Use

- Local backend failure
- Accidental state file deletion
- Need to recover previous state

### Important Notes

- **Solo workflow only** - rethink approach if team grows
- **Always backup after `terraform apply`**
- Versioning is enabled on S3 bucket for safety

### Configuration

Edit `backup.sh` if needed:

- Profile: `staging-piksel`
- Region: `ap-southeast-3`
- Bucket: `terraform-backup-staging-piksel-taufik`
