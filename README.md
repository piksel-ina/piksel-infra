# Piksel Infrastructure

This repository contains Terraform configurations for Piksel's AWS infrastructure.

## Repository Structure

```bash
.
├── LICENSE
├── README.md
├── .github/workflows         # Workflows for github action
└── terraform/
    ├── compute/              # For future compute resources
    ├── kubernetes/           # For future Kubernetes configurations
    ├── network/              # Network infrastructure
    └── shared/               # For shared resources across environments
```

## Environment

- **Development**:
  - Single-AZ setup in ap-southeast-3 (Jakarta)
  - Cost-optimized for development work
  - Not configured for high availability

## List of Deployed Infrastructure

- Network Infrastructure:
  - VPC (10.0.0.0/16)
  - Subnets:
    - Public: 10.0.0.0/24
    - Private App: 10.0.10.0/24
    - Private Data: 10.0.20.0/24
  - NAT Gateway
  - Internet Gateway
  - Route Tables
  - Security Groups

## Developer on Board

### Prerequisites

- AWS CLI configured
- Terraform 1.0+ installed
- Access to AWS account
- Pre-commit installed

### Pre-commit Setup

This project uses pre-commit to enforce code quality and consistency. The configuration includes:

- Basic file checks (YAML validation, whitespace cleanup)
- Terraform formatting, validation, and linting
- Automatic documentation generation

**Option 1: Installation: Using pipx**

```bash
# Install pipx if not already installed
sudo apt install pipx
pipx ensurepath  # Add to PATH

# Install pre-commit
pipx install pre-commit

# Verify installation
pre-commit --version
```

**Option 2: Using a Virtual Environment**

```bash
# Install necessary packages
sudo apt install python3-venv

# Create a dev tools environment
python3 -m venv ~/.venvs/devtools

# Activate the environment
source ~/.venvs/devtools/bin/activate

# Install pre-commit
pip install pre-commit

# Add to your ~/.bashrc or ~/.zshrc for convenience
echo 'alias pre-commit="~/.venvs/devtools/bin/pre-commit"' >> ~/.bashrc
source ~/.bashrc  # Or restart your terminal
```

### Local Testing

1. **AWS Authentication**

- **AWS SSO Setup**:

  - Request access from your administrator to be added as a user
  - Configure AWS SSO in your AWS CLI:
    ```bash
    aws configure sso
    ```
  - Follow the prompts to complete SSO configuration

- **Start SSO Session**:
  ```bash
  aws sso login --profile your-profile-name
  ```

2. **Local Backend Configuration**

- Create a `local_override.tf` file for local testing:

  ```hcl
  # This file is ignored by git
  terraform {
    backend "local" {
      path = "terraform.tfstate"
    }
  }
  ```

- Initialize with local backend:
  ```bash
  terraform init
  ```

### Testing Workflow

1. Make your infrastructure changes
2. Run pre-commit to validate:
   ```bash
   pre-commit run --all-files
   ```
3. Test locally:
   ```bash
   terraform plan
   ```
4. Apply only for testing purposes:
   ```bash
   terraform apply
   ```
5. After verification, destroy resources:
   ```bash
   terraform destroy
   ```

## Deployment Process

1. **Never** push applied changes to staging/production (`main` branch) directly from local environment
2. After testing locally, destroy all resources
3. Commit and push changes to the repository (`develop` branch for development)
4. CI/CD workflow will run validation checks
5. Terraform Cloud will handle the actual infrastructure deployment
6. Review the plan in Terraform Cloud before applying

Remember that all infrastructure changes should go through the CI/CD pipeline to maintain consistency and provide a proper audit trail.
