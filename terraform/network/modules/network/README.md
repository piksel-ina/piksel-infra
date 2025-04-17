# AWS VPC Network Module Documentation

## Overview

This Terraform module creates a complete AWS VPC network infrastructure with public and private subnets, supporting both application and data layer separation. The module follows AWS best practices for network segmentation and high availability.

## Architecture

The module creates:

- **VPC**: Main Virtual Private Cloud with DNS support
- **Internet Gateway**: For public internet access
- **Subnet Tiers**:
  - **Public Subnets**: For internet-facing resources like load balancers
  - **Private App Subnets**: For application workloads with optional EKS cluster integration
  - **Private Data Subnets**: For database and storage resources
- **NAT Gateways**: Configurable for high availability or cost optimization
- **Route Tables & Routes**: Properly configured for each subnet tier

## Features

- **Multi-AZ Support**: Deploy resources across multiple Availability Zones
- **Flexible NAT Gateway Options**:
  - Single NAT Gateway (cost-optimized)
  - Multiple NAT Gateways (high availability, one per AZ)
  - Configurable placement of NAT Gateways
- **Kubernetes Integration**: Optional tagging for EKS clusters
- **Consistent Tagging**: Apply common tags across all resources

## Usage

```hcl
module "network" {
  source = "./modules/network"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"

  public_subnets = {
    "public-subnet-1a" = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = "ap-southeast-3a"
    },
    "public-subnet-1b" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-southeast-3b"
    }
  }

  private_app_subnets = {
    "private-app-subnet-1a" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "ap-southeast-3a"
    },
    "private-app-subnet-1b" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "ap-southeast-3b"
    }
  }

  private_data_subnets = {
    "private-data-subnet-1a" = {
      cidr_block        = "10.0.20.0/24"
      availability_zone = "ap-southeast-3a"
    },
    "private-data-subnet-1b" = {
      cidr_block        = "10.0.21.0/24"
      availability_zone = "ap-southeast-3b"
    }
  }

  enable_nat_gateway = true
  single_nat_gateway = true  # Set to false for high availability
  azs_to_use         = ["ap-southeast-3a", "ap-southeast-3b"]

  cluster_name = "my-eks-cluster"  # Optional, for EKS integration

  common_tags = {
    Project     = "MyProject"
    ManagedBy   = "Terraform"
  }
}
```

## Required Variables

| Name                 | Description                                          | Type        | Required |
| -------------------- | ---------------------------------------------------- | ----------- | :------: |
| vpc_cidr             | CIDR block for the VPC                               | string      |   yes    |
| environment          | Environment name (dev, staging, prod)                | string      |   yes    |
| public_subnets       | Map of public subnets with CIDR blocks and AZs       | map(object) |   yes    |
| private_app_subnets  | Map of private app subnets with CIDR blocks and AZs  | map(object) |   yes    |
| private_data_subnets | Map of private data subnets with CIDR blocks and AZs | map(object) |   yes    |

## Optional Variables

| Name               | Description                                  | Type         | Default |
| ------------------ | -------------------------------------------- | ------------ | ------- |
| enable_nat_gateway | Enable NAT Gateway for private subnets       | bool         | false   |
| single_nat_gateway | Use only one NAT Gateway                     | bool         | false   |
| azs_to_use         | List of AZs where to deploy NAT Gateways     | list(string) | []      |
| cluster_name       | EKS cluster name for subnet tagging          | string       | ""      |
| common_tags        | Map of common tags to apply to all resources | map(string)  | {}      |

## Notes

1. When `single_nat_gateway` is true, only one NAT Gateway will be created in the first AZ listed in `azs_to_use`.
2. When `cluster_name` is provided, app subnets will include the required Kubernetes tags for EKS.
3. NAT Gateway routes are only created for private subnets in AZs with a NAT Gateway when not using a single NAT Gateway.

## Best Practices

1. **Cost Optimization**: Use `single_nat_gateway = true` for non-production environments.
2. **High Availability**: Set `single_nat_gateway = false` for production environments.
3. **Security Segregation**: Keep data tier resources in dedicated private subnets.
