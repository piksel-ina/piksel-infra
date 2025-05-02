# Piksel Infrastructure (`piksel-infra`)

This repository contains the Infrastructure as Code (IaC) definitions, managed by [Terraform](https://www.terraform.io/), for the Piksel project's AWS infrastructure. It follows GitOps principles for managing deployments across different environments.

## Maintainers

This repository is maintained by the **Piksel DevOps Team**.

## Repository Overview and Structure

The repository is organized by environment, ensuring clear separation and targeted configurations:

<!-- prettier-ignore-start -->
```
piksel-infra/
├── .github/
│ └── workflows/
│ └── tf-validate-lint.yml      # GitHub Action for PR checks
├── .gitignore
├── .pre-commit-config.yaml     # Pre-commit hook configurations
├── LICENSE
├── README.md                   # This file
├── dev/                        # Development Environment Configuration
│ ├── main.tf                   # Root module configuration for dev
│ ├── variables.tf              # Variable definitions for dev
│ ├── outputs.tf                # Outputs for dev
│ ├── providers.tf              # Provider configuration
│ └── dev.auto.tfvars           # **Environment-specific values (DO NOT commit secrets)**
├── shared/                     # Shared Environment Configuration (similar structure)
├── staging/                    # Staging Environment Configuration (similar structure)
└── prod/                       # Production Environment Configuration (similar structure)

```
<!-- prettier-ignore-end -->

- Each environment (`dev`, `staging`, `prod`, 'shared') has its own directory containing Terraform configuration (`.tf` files) and variable definitions (`.tfvars`).
- Configurations or complex resources might eventually be abstracted into local modules if needed, but the primary approach leverages modules directly from the Terraform Registry within each environment's `main.tf`.
- Terraform state is managed remotely using **Terraform Cloud**.

## Workflow: GitOps with Terraform Cloud

This repository employs a GitOps workflow integrated with Terraform Cloud (TFC):

1.  **Development:** Developers create feature branches from `main`.
2.  **Pull Request (PR):** When changes are ready, a PR is opened targeting the `main` branch.
3.  **Automated Checks (GitHub Actions):** The [`tf-validate-lint.yml`](./.github/workflows/tf-validate-lint.yml) workflow automatically runs on the PR to:
    - Check Terraform formatting (`terraform fmt -check`)
    - Validate Terraform configuration syntax (`terraform validate`)
    - Lint Terraform code for best practices and potential errors (`tflint`)
    - Scan for potential security issues (`tfsec`) - _(Note: `tfsec` scanning is planned but not yet implemented in the workflow)_
4.  **Review & Merge:** Code is reviewed, and upon approval, the PR is merged into `main`.
5.  **Automated Apply (Terraform Cloud):**
    - The merge to `main` triggers runs in the configured **Terraform Cloud** workspaces (connected via VCS).
    - **Organization:** `piksel-ina`
    - **Workspaces:**
      - `piksel-infra-dev` (Applies changes to the Development environment)
      - `piksel-infra-staging` (Applies changes to the Staging environment - requires TFC approval)
      - `piksel-infra-prod` (Applies changes to the Production environment - requires TFC approval)
    - TFC performs `terraform plan` and `terraform apply` based on the code in the `main` branch for the corresponding environment's workspace.
    - **Note:** Manual approval steps are configured within Terraform Cloud for `staging` and `prod` workspaces to prevent accidental deployments.

## Developer Collaboration Guide

### 1. Overall Project Strategy

Before contributing, please familiarize yourself with the overall project structure, branching strategy, and CI/CD principles outlined in the main repository strategy document:

➡️ **[Piksel Project Repository and CI/CD Strategy](https://github.com/piksel-ina/piksel-document/blob/main/operations/01-repository-strategy-and-cicd.md)**

### 2. Pre-commit Hooks

This repository uses `pre-commit` to automatically run checks (like formatting and validation) before you commit your changes locally. This helps catch errors early.

- **Setup:**

  ```bash
  # Install pre-commit (if you haven't already)
  pip install pre-commit

  # Install the git hook scripts for this repository
  pre-commit install
  ```

- **Usage:** Hooks run automatically when you run `git commit`. You can also run them manually on all files:
  ```bash
  pre-commit run --all-files
  ```
- **Configuration:** See the [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) file.

### 3. Local Testing (Validation Only)

While the primary workflow relies on TFC, you might need to run `terraform plan` or limited `apply` locally for validation _before_ pushing changes.

> **⚠️ IMPORTANT:**
>
> - **NEVER manage persistent `staging` or `prod` infrastructure locally.** Use the GitOps/TFC workflow exclusively.
> - Local testing should ideally target the `dev` environment or temporary resources.
> - **ALWAYS destroy resources created locally for testing purposes.**

**Steps for Local Validation:**

1.  **Override Backend:** Create a file named `local_override.tf` (this file is gitignored) in the environment directory (e.g., `dev/`) with the following content to switch from the TFC backend to a local backend:
    ```terraform
    # dev/local_override.tf
    terraform {
      backend "local" {}
    }
    ```
2.  **Authenticate:** Ensure you have an active AWS SSO session for the target account:
    ```bash
    # Replace with your actual SSO profile name
    aws sso login --profile your-piksel-sso-profile
    export AWS_PROFILE=your-piksel-sso-profile
    ```
3.  **Initialize & Plan/Apply:** Run Terraform commands as usual from the environment directory (e.g., `cd dev`):
    ```bash
    terraform init
    terraform plan
    # terraform apply # Use with extreme caution for validation only
    ```
4.  **CLEAN UP:** Once testing is complete, **destroy any resources you created locally**:
    ```bash
    terraform destroy
    ```
5.  **Remove Override:** Delete or rename `local_override.tf` before committing your actual changes to ensure the TFC backend is used in the main workflow.

### 4. Terraform Documentation (`terraform-docs`)

This repository uses `terraform-docs` (integrated via pre-commit) to automatically generate documentation about Terraform inputs, outputs, and providers based on the code.

- When you change variables or outputs, pre-commit hooks will update relevant documentation files (e.g., potentially within module READMEs or specific docs files if configured).
- Ensure any automatically generated documentation changes are included in your commits.

## Design Decisions

The infrastructure design choices are documented in the central `piksel-document` repository:

- **[Network Design](https://github.com/piksel-ina/piksel-document/blob/main/architecture/network.md)**
- **[S3 / Object Storage Design](https://github.com/piksel-ina/piksel-document/blob/main/architecture/object-storage.md)**
- **[RDS / Database Design](https://github.com/piksel-ina/piksel-document/blob/main/architecture/database.md)**
- **[ECR / Container Registry Design](https://github.com/piksel-ina/piksel-document/blob/main/architecture/container-registry.md)**
- **[DNS Design](https://github.com/piksel-ina/piksel-document/blob/main/architecture/dns.md)**
- **[IAM Strategy](https://github.com/piksel-ina/piksel-document/blob/main/architecture/iam-strategy.md)**

Please refer to these documents for the rationale behind the architectural decisions implemented in this repository.
