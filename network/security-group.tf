# --- Security Group ---
module "spoke_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "spoke-to-hub-sg"
  description = "Security Group for spoke VPC resources allowing traffic to hub VPC"
  vpc_id      = module.vpc.vpc_id

  # --- Ingress rules: Allow DNS (UDP/53) and TCP/53 from hub VPCs ---
  ingress_with_cidr_blocks = [
    {
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      description = "Allow DNS UDP response from hub VPC"
      cidr_blocks = var.vpc_cidr_shared
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "Allow DNS TCP response from hub VPC"
      cidr_blocks = var.vpc_cidr_shared
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS to ECR/S3 endpoints in hub VPC"
      cidr_blocks = var.vpc_cidr_shared
    }
  ]

  tags = var.default_tags
}
