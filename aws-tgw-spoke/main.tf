locals {
  prefix = "${lower(var.project)}-${lower(var.environment)}"
  tags   = var.default_tags
}

# -- Attach the spoke VPC to the shared Transit Gateway --
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_to_shared_tgw" {

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids

  dns_support = "enable"

  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-tgw-attachment"
  })
}

data "aws_route_tables" "vpc_route_tables" {
  vpc_id = var.vpc_id
}

# -- Add route to spoke-VPC's route table, it directs traffic to hub CIDR via TGW --
resource "aws_route" "spoke_to_shared_vpc_via_tgw" {
  count = length(data.aws_route_tables.vpc_route_tables.ids)

  route_table_id         = data.aws_route_tables.vpc_route_tables.ids[count.index]
  destination_cidr_block = var.vpc_cidr_shared
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw]
}
