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

# Use remote state to retrieve the network data
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "dev-finalproj-group1"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create AWS ALB
resource "aws_lb" "this" {
  name               = "${local.name_prefix}-${var.name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-${var.name}-alb"
    }
  )
}

# Create Target Group for ALB
resource "aws_lb_target_group" "this" {
  name     = "${local.name_prefix}-${var.name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
}

# Create listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  
  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-${var.name}-tg"
    }
  )
}