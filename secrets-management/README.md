# Usage Instructions

## Prerequisites

Before deploying secrets to each environment, the required external services need to be set up and the necessary credentials gathered.

## Setup Instructions for Each Environment

### 1. Auth0 Application Setup

For each environment (dev, staging, prod), separate Auth0 applications must be created for Grafana, JupyterHub, and Argo Workflows:

#### Create Applications in Auth0

1. Log in to the Auth0 Dashboard
2. Navigate to **Applications** → **Create Application**
3. For each service (Grafana, JupyterHub, Argo Workflows), configure the application:
   - **Name**: `{Service} - {environment}` (e.g., "Grafana - Dev", "JupyterHub - Staging", "Argo Workflows - Prod")
   - **Application Type**: Regular Web Application
4. Go to **Settings** tab and configure callback URLs based on the service:

   **Grafana:**

   - **Allowed Callback URLs**: `https://grafana-{env}.domain.com/login/generic_oauth`
   - **Allowed Logout URLs**: `https://grafana-{env}.domain.com`
   - **Allowed Web Origins**: `https://grafana-{env}.domain.com`

   **JupyterHub:**

   - **Allowed Callback URLs**: `https://jupyterhub-{env}.domain.com/hub/oauth_callback`
   - **Allowed Logout URLs**: `https://jupyterhub-{env}.domain.com`
   - **Allowed Web Origins**: `https://jupyterhub-{env}.domain.com`

   **Argo Workflows:**

   - **Allowed Callback URLs**: `https://argo-{env}.domain.com/oauth2/callback`
   - **Allowed Logout URLs**: `https://argo-{env}.domain.com`
   - **Allowed Web Origins**: `https://argo-{env}.domain.com`

5. Save the **Client ID** and **Client Secret** for each application to use in the tfvars file

### 2. Slack Webhook Setup

For each environment, dedicated Slack channels and webhooks must be created:

#### Create Slack Channels

1. Create environment-specific channels following the pattern:
   - `#flux-piksel-dev-env`
   - `#flux-piksel-staging-env`
   - `#flux-piksel-prod-env`

#### Create Incoming Webhooks

1. Go to the Slack workspace
2. Navigate to **Apps** → **Manage** → **Custom Integrations** → **Incoming Webhooks**
3. Click **Add to Slack**
4. For each environment:
   - Select the appropriate channel (`#flux-piksel-{env}-env`)
   - Customize the webhook name: `{Environment} Alerts` (e.g., "Dev Alerts")
   - Copy the **Webhook URL** for the tfvars file
   - Repeat for each environment

## Deployment Instructions

### Step 1: Prepare Environment-Specific Configuration Files

Copy the template file and create environment-specific configurations:

```bash
# Copy template for each environment
cp env.tfvars.example dev.tfvars
cp env.tfvars.example staging.tfvars
cp env.tfvars.example prod.tfvars
```

### Step 2: Configure Each Environment File

#### Edit `dev.tfvars`:

```hcl
region = "ap-southeast-3"

slack_secrets = {
  "slack-alerts" = {
    secret_string = "https://hooks.slack.com/services/DEV/WEBHOOK"
    description   = "Slack webhook for development alerts"
    project       = "project-name"
    service       = "monitoring"
    tenant        = "Slack"
  }
}

oauth_secrets = {
  "grafana-oauth" = {
    client_id     = "dev_grafana_client_id"
    client_secret = "dev_grafana_client_secret"
    description   = "Grafana OAuth client credentials for development"
    project       = "-project-name"
    service       = "grafana"
    tenant        = "Auth0"
  },
  "jupyterhub-oauth" = {
    client_id     = "dev_jupyterhub_client_id"
    client_secret = "dev_jupyterhub_client_secret"
    description   = "JupyterHub OAuth client credentials for development"
    project       = "-project-name"
    service       = "jupyterhub"
    tenant        = "Auth0"
  },
  "argo-workflows-oauth" = {
    client_id     = "dev_argo_client_id"
    client_secret = "dev_argo_client_secret"
    description   = "Argo Workflows OAuth client credentials for development"
    project       = "-project-name"
    service       = "argo-workflows"
    tenant        = "Auth0"
  }
}
```

Similar configuration should be applied to `staging.tfvars` and `prod.tfvars` with their respective credentials.

### Step 3: Deploy to Each Environment

#### Deploy to Development Environment:

```bash
# Authenticate with AWS SSO for DEV account
aws sso login --profile dev-profile

# Verify the correct AWS account
aws sts get-caller-identity

# Create and switch to dev workspace
terraform workspace new dev || terraform workspace select dev

# Initialize Terraform (if first time)
terraform init

# Plan and apply
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## Verification

After deployment, the secrets can be verified:

```bash
# List secrets in AWS Secrets Manager
aws secretsmanager list-secrets --region ap-southeast-3

# Get specific secret (replace with actual secret name)
aws secretsmanager get-secret-value --secret-id grafana-oauth-dev --region ap-southeast-3
```

## Security and Troubleshooting

1. **Never commit tfvars files** - They contain sensitive credentials
2. **Use separate AWS accounts** for each environment
3. **Rotate secrets regularly** in both Auth0 and AWS Secrets Manager

### Common Issues:

1. **Wrong AWS Account**: Always verify with `aws sts get-caller-identity`
2. **Workspace Confusion**: Check current workspace with `terraform workspace show`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.oauth_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.slack_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.oauth_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.slack_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_oauth_secrets"></a> [oauth\_secrets](#input\_oauth\_secrets) | Map of OAuth client secrets to create | <pre>map(object({<br/>    client_id     = string<br/>    client_secret = string<br/>    description   = string<br/>    project       = string<br/>    service       = string<br/>    tenant        = string<br/>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for secrets | `string` | `"ap-southeast-3"` | no |
| <a name="input_slack_secrets"></a> [slack\_secrets](#input\_slack\_secrets) | Map of Slack webhook secrets to create | <pre>map(object({<br/>    secret_string = string<br/>    description   = string<br/>    project       = string<br/>    service       = string<br/>    tenant        = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment"></a> [environment](#output\_environment) | Current environment (workspace) |
| <a name="output_oauth_secret_arns"></a> [oauth\_secret\_arns](#output\_oauth\_secret\_arns) | ARNs of created OAuth secrets |
| <a name="output_oauth_secret_names"></a> [oauth\_secret\_names](#output\_oauth\_secret\_names) | Names of created OAuth secrets |
| <a name="output_slack_secret_arns"></a> [slack\_secret\_arns](#output\_slack\_secret\_arns) | ARNs of created Slack secrets |
| <a name="output_slack_secret_names"></a> [slack\_secret\_names](#output\_slack\_secret\_names) | Names of created Slack secrets |
<!-- END_TF_DOCS -->
