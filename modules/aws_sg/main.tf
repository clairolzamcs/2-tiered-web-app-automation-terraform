provider "aws" {
  region = "us-east-1"
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

module "network" {
  source = "../aws_network"
}

# Creating Security Group for ELB
resource "aws_security_group" "elb" {
  name        = "ELB Security Group"
  description = "Security Group for ELB"
  vpc_id      = module.network.vpc_id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-Elb-Sg"
    }
  )
}