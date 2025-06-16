# Piksel Infrastructure (`piksel-infra`)

This repository contains the Infrastructure as Code (IaC) definitions, managed by [Terraform](https://www.terraform.io/), for the Piksel project's AWS infrastructure. It follows GitOps principles for managing deployments across different environments.

## 1. Infrastructure Design

### 1.1. Network

Piksel’s AWS infrastructure uses a hub-and-spoke network architecture, where a central “hub” account manages shared services like DNS, ECR, and network routing, while isolated “spoke” accounts (for environments such as dev, staging, and prod) run workloads. This design leverages AWS Transit Gateway to enable private, secure connectivity between accounts—especially for pulling container images from a centralized ECR—ensuring that traffic stays off the public internet.

**Network Diagram:**

<img src=".images/spoke-network.png" width="700" height="auto">

For more details, see:

[**🔗 Piksel Spoke Network Design**](https://github.com/piksel-ina/piksel-document/blob/main/architecture/spoke-network-design.md)

### 1.2. EKS Cluster Design

The Piksel EKS clusters are designed for scalability, security, and efficient operations within the spoke account VPCs. Key design aspects include:

- **Managed Control Plane:** Utilizes AWS EKS for a managed, highly available Kubernetes control plane.
- **Dynamic Node Provisioning:** Employs [Karpenter](https://karpenter.sh/) for efficient, just-in-time provisioning of EC2 nodes based on workload requirements, optimizing for cost and performance.
- **Serverless Compute:** Leverages [AWS Fargate](https://aws.amazon.com/fargate/) profiles for running specific stateless workloads without managing underlying EC2 instances.
- **Secure Pod Permissions:** Implements IAM Roles for Service Accounts (IRSA) to grant fine-grained AWS permissions directly to Kubernetes service accounts.
- **Secrets Management:** Integrates securely with AWS Secrets Manager for managing sensitive information like API keys and database credentials.
- **GitOps Application Deployment:** Cluster state and application deployments are managed declaratively via GitOps tooling (Flux CD) configured in the [piksel-gitops](https://github.com/piksel-ina/piksel-gitops) repository.
- **Provisioning:** The Terraform code within _this repository_ is responsible for provisioning and managing the lifecycle of this EKS cluster design and its core AWS dependencies (VPC, IAM, RDS, S3, etc.).

**EKS Cluster Diagram:**

<img src=".images/eks-cluster-overview.png" width="700" height="auto">

For a comprehensive overview of the cluster architecture and each component, please refer to:

1. [**EKS Cluster Design**](https://github.com/piksel-ina/piksel-document/blob/main/architecture/eks-cluster-design.md),
2. [**EKS Add-ons Configuration**](https://github.com/piksel-ina/piksel-document/blob/main/architecture/eks-addons.md),
3. [**Karpenter Configuration**](https://github.com/piksel-ina/piksel-document/blob/main/architecture/karpenter.md)

## 2. Developer Access

### 2.1. Add Secret to AWS Secrets Manager

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
