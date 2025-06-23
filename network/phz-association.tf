# --- Route53 Zone Association ---
resource "aws_route53_zone_association" "vpc_association" {
  for_each = var.private_zone_ids

  zone_id = each.value
  vpc_id  = module.vpc.vpc_id
}

resource "aws_vpc_dhcp_options" "spoke_dhcp" {
  domain_name_servers = concat(var.inbound_resolver_ip_addresses, ["AmazonProvidedDNS"])

  tags = var.default_tags
}

resource "aws_vpc_dhcp_options_association" "spoke_dhcp_assoc" {
  vpc_id          = module.vpc.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.spoke_dhcp.id
}
