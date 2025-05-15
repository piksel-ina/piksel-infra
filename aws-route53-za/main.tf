variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the resolver rule"
  type        = string
}

variable "zone_ids" {
  description = "List of Route53 Hosted Zone IDs to associate with the VPC"
}

locals {
  prefix = "${lower(var.project)}-${lower(var.environment)}"
}


# --- Route53 Zone Association ---
resource "aws_route53_zone_association" "vpc_association" {
  for_each = var.zone_ids

  zone_id = each.value
  vpc_id  = var.vpc_id
}

# --- Route53 Association Outputs ---

output "private_zone_association_owner_id" {
  description = "The account ID of the account that created the hosted zone"
  value       = [for zone in aws_route53_zone_association.vpc_association : zone.owning_account]
}
