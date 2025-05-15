# --- Zone Configuration ---
locals {
  zones_config = {
    "${var.domain_name}" = {
      comment = "Public zone for ${var.domain_name}"
      tags = {
        Name = var.domain_name
      }
      timeouts = {
        create = "2h"
        update = "3h"
        delete = "1h"
      }
    }

    "${var.subdomain_name}" = {
      comment = "Public zone for ${var.subdomain_name}"
      tags = {
        Name = var.subdomain_name
      }
    }

    "${var.private_domain_name_hub}" = {
      domain_name = var.private_domain_name_hub
      comment     = "Private zone for ${var.private_domain_name_hub}"
      vpc = [
        {
          vpc_id = var.vpc_id_shared
        }
      ]
      tags = {
        Name = var.private_domain_name_hub
      }
    }

    "${var.private_domain_name_dev}" = {
      domain_name = var.private_domain_name_dev
      comment     = "Private zone for ${var.private_domain_name_dev}"
      vpc = [
        {
          vpc_id = var.vpc_id_shared
        }
      ]
      tags = {
        Name = var.private_domain_name_dev
      }
    }

    "${var.private_domain_name_prod}" = {
      domain_name = var.private_domain_name_prod
      comment     = "Private zone for ${var.private_domain_name_prod}"
      vpc = [
        {
          vpc_id = var.vpc_id_shared
        }
      ]
      tags = {
        Name = var.private_domain_name_dev
      }
    }
  }

  prefix = "${lower(var.project)}-${lower(var.environment)}"
  tags   = var.default_tags
}

# --- Route53 Hosted Zones ---
module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 5.0"

  zones = local.zones_config

  tags = local.tags
}

# --- Records for main public zones ---
module "records_public" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 5.0"

  create     = var.enable_records_public
  zone_name  = var.domain_name
  depends_on = [module.zones]

  records = []
}

# --- Records for subdomain public zones ---
module "records_subdomain" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 5.0"

  create     = var.enable_records_subdomain
  zone_name  = var.subdomain_name
  depends_on = [module.zones]

  records = []
}

# --- Records for private zones ---
module "records_private_dev" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 5.0"

  create     = var.enable_records_private_dev
  zone_name  = var.private_domain_name_dev
  depends_on = [module.zones]

  records = [
    # {
    #     name    = "db.dev.piksel.internal"
    #     type    = "CNAME"
    #     ttl     = "300"
    #     records = [local.dev_odc_rds_address]
    # }
  ]
}

module "records_private_prod" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 5.0"

  create     = var.enable_records_private_prod
  zone_name  = var.private_domain_name_prod
  depends_on = [module.zones]

  records = []
}


# --- INBOUND RESOLVER ENDPOINT ---
module "inbound_resolver_endpoint" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-endpoints"
  version = "~> 5.0"

  create    = var.create_inbound_resolver_endpoint
  name      = "${local.prefix}-inbound-resolver"
  direction = "INBOUND"
  vpc_id    = var.vpc_id_shared

  protocols = ["Do53"]

  # Provide at least two subnets in different AZs
  ip_address = [
    { subnet_id = var.private_subnets[0] },
    { subnet_id = var.private_subnets[1] }
  ]

  # Create security group
  create_security_group              = true
  security_group_name                = "${var.project}-resolver-inbound-sg"
  security_group_description         = "Allow DNS queries to Inbound Resolver Endpoint for ${var.project}"
  security_group_ingress_cidr_blocks = concat(var.spoke_vpc_cidrs, [var.vpc_cidr_block_shared])

  tags                = merge(local.tags, { Name = "${var.project}-inbound-resolver" })
  security_group_tags = merge(local.tags, { Name = "${var.project}-resolver-inbound-sg" })
}

# --- OUTBOUND RESOLVER ENDPOINT ---
module "outbound_resolver_endpoint" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-endpoints"
  version = "~> 5.0"

  create    = var.create_outbound_resolver_endpoint
  name      = "${local.prefix}-outbound-resolver"
  direction = "OUTBOUND"
  vpc_id    = var.vpc_id_shared

  protocols = ["Do53"]

  ip_address = [
    { subnet_id = var.private_subnets[0] },
    { subnet_id = var.private_subnets[1] }
  ]

  # Create the security group
  create_security_group              = true
  security_group_name                = "${local.prefix}-resolver-outbound-sg"
  security_group_description         = "Allow DNS queries from Outbound Resolver Endpoint for ${var.project}"
  security_group_ingress_cidr_blocks = [var.vpc_cidr_block_shared]

  tags                = merge(local.tags, { Name = "${local.prefix}-outbound-resolver" })
  security_group_tags = merge(local.tags, { Name = "${local.prefix}-resolver-outbound-sg" })
}


# --- Authorization for VPC Association ---
resource "aws_route53_vpc_association_authorization" "dev_vpc_authorization" {
  zone_id    = module.zones.route53_zone_zone_id["${var.private_domain_name_dev}"]
  vpc_id     = var.vpc_id_dev
  depends_on = [module.zones]
}

// Add authorization for prod VPC association after prod vpc is created
