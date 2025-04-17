# Piksel Network Infrastructure - Quick Reference (Development)

## Overview

Minimalist AWS VPC configuration for the Piksel project's dev environment, optimized for cost over high availability.

## Key Configuration

- **Environment**: Development (`dev`)
- **Region**: ap-southeast-3 (Jakarta)
- **Architecture**: Single-AZ deployment (ap-southeast-3a only)
- **VPC CIDR**: 10.0.0.0/16

## Network Layout

| Type                | CIDR         | Purpose                   |
| ------------------- | ------------ | ------------------------- |
| Public Subnet       | 10.0.0.0/24  | Internet-facing resources |
| Private App Subnet  | 10.0.10.0/24 | Application workloads     |
| Private Data Subnet | 10.0.20.0/24 | Databases and storage     |

## Design Decisions

- **Single AZ**: Cost-optimized but not fault-tolerant
- **Single NAT Gateway**: Provides internet access for private resources
- **Separated subnets**: Maintains network segmentation best practices

## Resource Identification

All resources tagged with:

```hcl
Project     : Piksel
Environment : dev
Owner       : Piksel Dev Team
ManagedBy   : Terraform
```

## Notes

- **Not production-ready**: Current setup trades availability for cost savings
- **Future EKS ready**: Configuration prepared for container workloads
- **Scaling path**: For production, expand to multi-AZ with multiple NAT gateways
