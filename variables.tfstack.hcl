# --- Common Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
  default     = "Piksel"
}

variable "environment" {
  description = "The environment of the deployment"
  type        = string
}

variable "aws_region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "ap-southeast-3"
}

variable "default_tags" {
  description = "A map of default tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}

variable "aws_virginia" {
  description = "us-east-1 / virginia region"
  type        = string
  default     = "us-east-1"
}

# --- AWS OIDC Variables ---
variable "aws_token" {
  type      = string
  ephemeral = true
}

variable "aws_role" {
  type = string
}

# --- VPC Configuration Variables ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use for subnets"
  type        = number
  default     = 2
}

# --- NAT Gateway Configuration ---
variable "single_nat_gateway" {
  description = "Enable a single NAT Gateway for all private subnets (cheaper, less availability)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Enable one NAT Gateway per Availability Zone (higher availability, higher cost)"
  type        = bool
  default     = false
}

# --- VPC Flow Logs Configuration ---
variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for monitoring network traffic"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention period for VPC Flow Logs in CloudWatch (in days)"
  type        = number
  default     = 90
}

# --- Route53 Zone Association Variables ---
variable "inbound_resolver_ip_addresses" {
  description = "List of inbound resolver ip addresses"
  type        = list(string)
}

variable "private_zone_ids" {
  description = "The ID of the private hosted zone"
  type        = map(string)
  default     = {}
}

# --- Transit Gateway Attachment and Routes variables ---
variable "vpc_cidr_shared" {
  description = "CIDR block for the hub VPC"
  type        = string
}

variable "transit_gateway_id" {
  description = "ID of the shared Transit Gateway from hub account"
  type        = string
}

# --- EKS Cluster Variables ---
variable "cluster_name" {
  description = "Name of the EKS cluster for tagging subnets"
  type        = string
}

variable "eks-version" {
  type        = string
  description = "The version of Kubernetes for this environment"
  default     = "1.32"
}

variable "coredns-version" {
  type        = string
  description = "The version of CoreDNS for this environment"
  default     = "v1.11.4-eksbuild.2"
}

variable "vpc-cni-version" {
  type        = string
  description = "The version of VPC CNI for this environment"
  default     = "v1.19.2-eksbuild.1"
}

variable "kube-proxy-version" {
  type        = string
  description = "The version of kube-proxy for this environment"
  default     = "v1.32.0-eksbuild.2"
}

variable "sso-admin-role-arn" {
  type        = string
  description = "The ARN of SSO Admin group"
}

# --- External DNS Variables ---
variable "subdomains" {
  description = "List of domain filters for ExternalDNS"
  type        = list(string)
}

variable "externaldns_crossaccount_role_arn" {
  description = "The ARN of the cross-account IAM role in Route53 account"
  type        = string
}

variable "public_hosted_zone_id" {
  description = "The ID of the public hosted zone"
  type        = string
}

# --- Karpenter Variables ---

variable "default_nodepool_ami_alias" {
  description = "AMI alias for default node pools"
  type        = string
  default     = "al2023@v20250505"
}

variable "gpu_nodepool_ami" {
  description = "AMI for GPU node pools"
  type        = string
  default     = "amazon-eks-node-al2023-x86_64-nvidia-1.32-v20250505"
}

variable "default_nodepool_node_limit" {
  description = "Default node limit for node pools"
  type        = number
  default     = 10000
}

variable "gpu_nodepool_node_limit" {
  description = "Default GPU node limit for GPU node pools"
  type        = number
  default     = 20
}

# --- Database Variables ---
variable "db_instance_class" {
  description = "Database instance class (e.g., db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage in gibibytes for the RDS instance"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "oauth_tenant" {
  description = "The oauth tenant URL"
  type        = string
}

variable "read_external_buckets" {
  description = "List of external S3 bucket names"
  type        = list(string)
  default     = []
}

variable "odc_cloudfront_crossaccount_role_arn" {
  description = "value of the cross-account IAM role in CloudFront account"
  type        = string
}

variable "efs_backup_enabled" {
  description = "Enable EFS backup policy"
  type        = bool
  default     = false
}
