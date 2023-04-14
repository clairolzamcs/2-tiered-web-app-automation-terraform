provider "aws" {
  region = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  default_tags = merge(
    module.globalvars.default_tags,
    {
      "Env" = var.env
    }
  )
  prefix      = module.globalvars.prefix
  name_prefix = "${local.prefix}-${var.env}"
}

module "globalvars" {
  source = "../globalvars"
}

# Create a new VPC 
resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-vpc"
    }
  )
}

# Add provisioning of the public subnet in the VPC
resource "aws_subnet" "public" {
  count             = length(var.public_cidr_blocks)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index + 1]

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-public-subnet-${count.index + 1}"
    }
  )
}

# Add provisioning of the private subnet in the VPC
resource "aws_subnet" "private" {
  count             = length(var.private_cidr_blocks)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index + 1]

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-private-subnet-${count.index + 1}"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-igw"
    }
  )
}

# Create NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public[1].id

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-ngw"
    }
  )
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "this" {
  vpc = true

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-ngw-igw"
    }
  )
}

# Route table to route add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-public-route-table"
    }
  )
}

# Route table to route add default gateway pointing to NAT Gateway (NGW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-private-route-table"
    }
  )
}

# Associate subnets with the custom public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

# Associate subnets with the custom private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}
