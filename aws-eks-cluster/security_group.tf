# --- Security Group for Node Groups ---
resource "aws_security_group" "node_group_sg" {
  name_prefix = "${local.cluster}-node-group-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "Cluster API to node groups"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  # EFS mount target access
  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.cluster}-node-group-sg"
  })
}
