# --- Security Group Configurations ---

# --- 1st Security Group: Spoke to Hub ---
module "spoke_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "spoke-to-hub-sg"
  description = "Security Group for spoke VPC resources allowing traffic to hub VPC"
  vpc_id      = var.vpc_id

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
    }
  ]

  tags = var.default_tags
}

# --- 2nd Security Group: Database ---
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "db-sg"
  description = "PostgreSQL security group"
  vpc_id      = var.vpc_id

  # --- Ingress rules: Allowing PostgreSQL traffic (port 5432) within the VPC ---
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]

  tags = var.default_tags
}
