# --- Database Security Group ---
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
