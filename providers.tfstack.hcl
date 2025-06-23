required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.95"
  }
  tls = {
    source  = "hashicorp/tls"
    version = ">= 4.0"
  }
  time = {
    source  = "hashicorp/time"
    version = ">= 0.9"
  }
  cloudinit = {
    source  = "hashicorp/cloudinit"
    version = ">= 2.0"
  }
  null = {
    source  = "hashicorp/null"
    version = ">= 3.0"
  }
  # kubernetes = {
  #   source  = "hashicorp/kubernetes"
  #   version = "~> 2.0"
  # }
  # helm = {
  #   source  = "hashicorp/helm"
  #   version = "~> 2.0"
  # }
  # random = {
  #   source  = "hashicorp/random"
  #   version = "~> 3.0"
  # }
}

provider "aws" "configurations" {
  config {
    region = var.aws_region
    assume_role_with_web_identity {
      role_arn           = var.aws_role
      web_identity_token = var.aws_token
    }
    default_tags {
      tags = var.default_tags
    }
  }
}

provider "aws" "virginia" {
  config {
    region = "us-east-1"
    assume_role_with_web_identity {
      role_arn           = var.aws_role
      web_identity_token = var.aws_token
    }
    default_tags {
      tags = var.default_tags
    }
  }
}

# provider "aws" "cross_account" {
#   config {
#     region = var.aws_region
#     assume_role_with_web_identity {
#       role_arn           = var.aws_role
#       web_identity_token = var.aws_token
#     }
#     assume_role {
#       role_arn = var.odc_cloudfront_crossaccount_role_arn
#     }
#     default_tags {
#       tags = var.default_tags
#     }
#   }
# }

# provider "kubernetes" "configurations" {
#   config {
#     host                   = component.eks-cluster.cluster_endpoint
#     cluster_ca_certificate = base64decode(component.eks-cluster.cluster_certificate_authority_data)
#     token                  = component.eks-cluster.authentication_token
#   }
# }

# provider "helm" "configurations" {
#   config {
#     kubernetes {
#       host                   = component.eks-cluster.cluster_endpoint
#       cluster_ca_certificate = base64decode(component.eks-cluster.cluster_certificate_authority_data)
#       token                  = component.eks-cluster.authentication_token
#     }
#   }
# }

provider "tls" "this" {}
provider "time" "this" {}
provider "cloudinit" "this" {}
provider "null" "this" {}
# provider "random" "this" {}
