# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-vpc"
      Environment = var.environment
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-igw"
      Environment = var.environment
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.key}"
      Environment = var.environment
    }
  )
}

# Private App Subnets
resource "aws_subnet" "private_app" {
  for_each = var.private_app_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.key}"
      Environment = var.environment
    },
    var.cluster_name != "" ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    } : {}
  )
}

# Private Data Subnets
resource "aws_subnet" "private_data" {
  for_each = var.private_data_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.key}"
      Environment = var.environment
    }
  )
}

# Determine which public subnets will have NAT Gateways
locals {
  # If single_nat_gateway is true, only use the first AZ from azs_to_use
  nat_gateway_azs = var.single_nat_gateway && length(var.azs_to_use) > 0 ? [var.azs_to_use[0]] : var.azs_to_use
  
  # Filter public subnets to only those in the AZs we're using for NAT Gateways
  public_subnets_with_nat = {
    for k, v in var.public_subnets :
    k => v if contains(local.nat_gateway_azs, v.availability_zone) && var.enable_nat_gateway
  }
  
  # Map to link private subnets to their corresponding public subnet's NAT Gateway
  # This handles routing for private subnets in AZs that have NAT Gateways
  private_subnet_nat_mapping = {
    for k, v in merge(var.private_app_subnets, var.private_data_subnets) :
    k => var.single_nat_gateway ? 
         keys(local.public_subnets_with_nat)[0] : 
         [for pk, pv in local.public_subnets_with_nat : pk if pv.availability_zone == v.availability_zone][0]
    if var.enable_nat_gateway && (var.single_nat_gateway || contains(local.nat_gateway_azs, v.availability_zone))
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = local.public_subnets_with_nat
  
  domain = "vpc"
  
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-nat-eip-${each.key}"
      Environment = var.environment
    }
  )
}

# NAT Gateways - only in specified AZs
resource "aws_nat_gateway" "main" {
  for_each = local.public_subnets_with_nat
  
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-nat-${each.key}"
      Environment = var.environment
    }
  )
}

# Route tables for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-public-rt"
      Environment = var.environment
    }
  )
}

# Route to Internet Gateway for public subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  for_each = var.public_subnets
  
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  for_each = merge(var.private_app_subnets, var.private_data_subnets)
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.key}-rt"
      Environment = var.environment
    }
  )
}

# Routes to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  for_each = local.private_subnet_nat_mapping
  
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.value].id
}

# Associate private app subnets with private route tables
resource "aws_route_table_association" "private_app" {
  for_each = var.private_app_subnets
  
  subnet_id      = aws_subnet.private_app[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Associate private data subnets with private route tables
resource "aws_route_table_association" "private_data" {
  for_each = var.private_data_subnets
  
  subnet_id      = aws_subnet.private_data[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

