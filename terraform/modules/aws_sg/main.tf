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

# Use remote state to retrieve the data
data "terraform_remote_state" "network" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "${var.env}-finalproj-group1" // Bucket from where to GET Terraform State
    key    = "network/terraform.tfstate"   // Object name in the bucket to GET Terraform State
    region = "us-east-1"                   // Region where bucket created
  }
}

# Create Security Group Module
resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-${var.name}" // default: group1-dev-sg
  description = "${local.name_prefix}-${var.desc}" // default: group1-dev-sg-description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules

    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-${var.name}-sg" // Default: group1-dev-sg-sg
    }
  )
}