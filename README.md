# Piksel Infrastructure (`piksel-infra`)

This repository contains the Infrastructure as Code (IaC) definitions, managed by [Terraform](https://www.terraform.io/), for the Piksel project's AWS infrastructure. It follows GitOps principles for managing deployments across different environments.

## Developer Access

### Add Secret to AWS Secrets Manager

1. **Authenticate with AWS SSO**
   If you haven't configure any sso session, please follow this guide - [Configure SSO with Piksel URL](https://github.com/piksel-ina/piksel-document/blob/main/operations/02-AWS-identity-center-guide.md#aws-cli-setup-and-access)

2. **Verify Your AWS Account**
   Before proceeding, ensure you are operating in the correct AWS account:

   ```bash
   aws sts get-caller-identity
   ```

3. **Add the Secret to AWS Secrets Manager**

   _Note: Replace the placeholders (`<...>`) with the actual values._

- Use the following command to create **Slack webhook** secret.
  ```bash
  aws secretsmanager create-secret \
      --name <slack-secret-name> \
      --secret-string <https://hooks.slack.com/services/EXAMPLELONGSTRIN> \
      --description "<Secret description>" \
      --tags \
          Key=Project,Value=<projectname> \
          Key=Service,Value=<servicename> \
          Key=Environment,Value=<env name> \
          Key=Owner,Value=Piksel-Devops-Team \
          Key=Tenant,Value=Slack \
      --region ap-southeast-3
  ```
- As for the OAuth Client Secret (**Grafana, JupyterHub, or Argo Workflow**):
  ```bash
  aws secretsmanager create-secret \
    --name <secret-name> \
    --secret-string <client_id_here>:<client_secret_here> \
    --description "<description>" \
    --tags \
      Key=Project,Value=<projectname> \
      Key=Service,Value=<servicename> \
      Key=Environment,Value=<env name> \
      Key=Owner,Value=Piksel-Devops-Team \
      Key=Tenant,Value=Auth0 \
    --region ap-southeast-3
  ```

## Maintainers

This repository is maintained by the **Piksel DevOps Team**.
