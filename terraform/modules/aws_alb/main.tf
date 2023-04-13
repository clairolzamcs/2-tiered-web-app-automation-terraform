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
    key    = "dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use remote state to retrieve the sg data
data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "dev-finalproj-group1"
    key    = "dev/sg/terraform.tfstate"
    region = "us-east-1"
  }
}

# Create AWS ALB
resource "aws_lb" "this" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    "${data.terraform_remote_state.sg.outputs.alb_sg}"
  ]
  subnets = data.terraform_remote_state.network.outputs.public_subnet_ids

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-Elb"
    }
  )
}

# Create Target Group for ALB
resource "aws_lb_target_group" "this" {
  name     = "web-lb-tg"
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
}