# -- Attach the spoke VPC to the shared Transit Gateway --
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_to_shared_tgw" {

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  dns_support = "enable"

  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-tgw-attachment"
  })
}

# -- Add route to spoke-VPC's route table, it directs traffic to hub CIDR via TGW --
resource "aws_route" "spoke_to_shared_vpc_via_tgw" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = var.vpc_cidr_shared
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw]
}
