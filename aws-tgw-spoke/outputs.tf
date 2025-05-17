# --- TGW Attachment Outputs ---
output "tgw_attachment_arn" {
  description = "The ARN of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.arn
}

output "tgw_attachment_id" {
  description = "The ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.id
}

output "tgw_vpc_owner_id" {
  description = "The owner ID of the Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_to_shared_tgw.vpc_owner_id
}

# --- Route Table Outputs ---
output "spoke_to_shared_vpc_via_tgw_route_id" {
  description = "The ID of the route to the shared VPC via Transit Gateway"
  value       = [for rtb in aws_route.spoke_to_shared_vpc_via_tgw : rtb.id]
}
output "spoke_to_shared_vpc_via_tgw_route_state" {
  description = "The state of the route to the shared VPC via Transit Gateway"
  value       = [for rtb in aws_route.spoke_to_shared_vpc_via_tgw : rtb.state]
}
