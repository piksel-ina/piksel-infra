# AGENTS.md — Piksel Infrastructure

Terraform IaC for the Piksel project on AWS (`ap-southeast-3`). Two independent Terraform roots, no root-level config.

| Env | Dir | AWS Profile | What it manages |
|---|---|---|---|
| **Staging** | `staging/` | `staging-piksel` | Full EKS stack via shared modules |
| **Dev** | `dev/` | `dev-piksel` | EC2 dev instances with auto-stop (standalone) |

Shared modules (`networks/`, `aws-eks-cluster/`, `aws-database/`, `karpenter/`, `applications/`, `external-dns/`, `aws-s3-bucket/`, `secrets-management/`, `amazon-observability/`) are consumed by staging only via `source = "../<module>"`.

## Change Workflow

Every infrastructure change follows this sequence. Do not skip steps.

```
make fmt                    # format first — unformatted code fails pre-commit
make validate-<env>         # syntax + type check
make plan-<env>             # review plan before applying
make apply-<env>            # apply changes
make backup-<env>           # back up state to S3 after apply
make pre-commit             # run before committing (terraform_fmt + terraform_docs)
```

New module or provider added? Run `make init-<env>` first.

## Code Conventions

- **Terraform**: `1.11.0-alpha20250107`. **AWS provider**: `= 5.95` (staging), `>= 5.0` (dev).
- **Block ordering** in resources: `count`/`for_each` → arguments → `tags` → `depends_on` → `lifecycle`.
- **Block ordering** in variables: `description` → `type` → `default` → `validation` → `nullable`.
- **Every variable and output must have `description` and `type` defined.** No exceptions.
- Singleton resources use `"this"` naming. Multiple same-type resources use descriptive names.
- `terraform_docs` pre-commit hook auto-generates module READMEs — never hand-edit them.
- Kubernetes/Helm/kubectl providers use `aws eks get-token` exec plugin — `awscli` must be installed.

## State & Secrets

- State is **local** (`*.tfstate` gitignored). Back up after every apply with `make backup-<env>` (uploads to S3 via `backup.sh`).
- Restore: run `backup.sh get` inside the env dir, files land in `tf_backup/`.
- `*.tfvars` and `*.auto.tfvars` are gitignored. `dev/dev.auto.tfvars` is the one exception.
- `dev/.secrets/` holds generated SSH keys — also gitignored.

## Cluster Checks (Staging)

Scripts in `scripts/` use variables exported by the Makefile (colors, AWS profile, region, cluster name, etc.).

| Target | What it does |
|---|---|
| `make check-context` | Show current kubectl context and cluster info |
| `make check-ami` | Compare running node AMIs against AWS recommended versions |
| `make check-versions` | Compare installed addon versions against AWS recommendations |
| `make check-health` | Check cluster health and pod status |
| `make check-endpoints` | Auto-discover and test LoadBalancer + Ingress endpoints (parallel) |
| `make restart-deployments` | Restart all deployments (interactive confirmation) |
| `make scan-deprecated` | Scan cluster for deprecated Kubernetes APIs using `pluto` |

## Danger Zones

- **Never run `terraform destroy` in any environment.**
- Never modify `.tfstate` files directly — use `terraform state` commands.
- Never move or rename module directories — relative `source` paths in `staging/main.tf` will break.
- Staging cross-account IAM roles (hub account `686410905891`) are hardcoded in `staging/providers.tf` and `staging/main.tf` — changing these breaks DNS and CloudFront.
- `lifecycle { ignore_changes = all }` on dev EC2 instances — Terraform won't detect manual changes.
- `dev/` and `staging/` are independent roots — there is no root-level config to init.
