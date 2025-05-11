aws_region  = "ap-southeast-3"
project     = "Piksel"
environment = "Shared"

# IMPORTANT: Choose a CIDR that DOES NOT overlap with dev, staging, prod, or other networks
vpc_cidr = "10.1.0.0/16"

# ASN for the new Transit Gateway (can be any private ASN)
transit_gateway_amazon_side_asn = 64512

common_tags = {
  Owner   = "DevOps-Team"
  Service = "Piksel-Shared"
  # Add any other globally relevant tags
}

tgw_ram_principals = [
  "236122835646" # Dev Account ID, add staging and production ID here
]

internal_domains = {
  main_internal = "piksel.internal",
  dev           = "dev.piksel.internal"
  # staging = "staging.piksel.internal"
  # prod    = "prod.piksel.internal"
}

resolver_rule_domain_name = "piksel.internal"

# Define DNS records
# public_dns_records = [
# Uncomment and modify when domain have been registered and set up services
# {
#   name    = ""
#   type    = "A"
#   ttl     = 3600
#   records = ["192.0.2.1"]
# },
# {
#   name    = "www"
#   type    = "CNAME"
#   ttl     = 3600
#   records = ["piksel.big.go.id"]
# }
# ]

spoke_vpc_cidrs = [
  "10.0.0.0/16", # CIDR for Spoke Dev VPC
]
