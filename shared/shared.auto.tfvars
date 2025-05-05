aws_region  = "ap-southeast-3"
project     = "piksel"
environment = "shared"

# IMPORTANT: Choose a CIDR that DOES NOT overlap with dev, staging, prod, or other networks
vpc_cidr = "10.1.0.0/16"

# ASN for the new Transit Gateway (can be any private ASN)
transit_gateway_amazon_side_asn = 64512

common_tags = {
  Owner = "DevOps-Team"
  # Add any other globally relevant tags
}

tgw_ram_principals = [
  "236122835646" # Dev Account ID, add staging and production ID here
]
