################################################################################
# EKS Cluster Security Group
################################################################################
resource "aws_security_group" "eks_cluster" {
  name        = "${local.name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_inbound" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow worker nodes to communicate with the cluster API Server"
}

resource "aws_security_group_rule" "cluster_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow all outbound traffic"
}

################################################################################
# EKS Node Group Security Group
################################################################################
resource "aws_security_group" "node_group" {
  name        = "${local.name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name                                          = "${local.name}-node-sg"
    "kubernetes.io/cluster/${local.name}-cluster" = "owned"
  })
}

resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

resource "aws_security_group_rule" "nodes_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node_group.id
  description       = "Allow all outbound traffic"
}

################################################################################
# ALB Security Group
################################################################################
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP inbound traffic"
}

resource "aws_security_group_rule" "alb_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS inbound traffic"
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

################################################################################
# Database Security Group
################################################################################
resource "aws_security_group" "database" {
  name        = "${local.name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "${local.name}-db-sg"
  })
}

resource "aws_security_group_rule" "database_inbound" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group.id
  security_group_id        = aws_security_group.database.id
  description              = "Allow PostgreSQL access from EKS nodes"
}
