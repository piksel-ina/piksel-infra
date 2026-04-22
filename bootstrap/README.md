# Bootstrap — Terraform Remote State Bucket

Creates one S3 bucket per workspace for storing Terraform state. Run once per AWS account.

## Usage

```bash
cd bootstrap/
export AWS_PROFILE=<profile>

terraform init
terraform workspace new <env>        # staging | production
terraform apply
```

## Workspace state

State files are stored locally in `terraform.tfstate.d/<env>/` and committed to git. This is intentional — the module manages one rarely-changed bucket per workspace.

## After bootstrap

Add to the environment's `providers.tf` `terraform` block:

```hcl
  backend "s3" {
    bucket       = "piksel-<env>-tfstate"
    key          = "<env>/terraform.tfstate"
    region       = "ap-southeast-3"
    use_lockfile = true
    encrypt      = true
  }
```

Then migrate:

```bash
cd ../staging/
terraform init
```

## CI/CD

Once ARC runners are deployed in EKS, terraform operations run from CI and use this S3 backend natively — no local state management needed.
