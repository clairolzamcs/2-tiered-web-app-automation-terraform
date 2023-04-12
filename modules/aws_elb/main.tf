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

module "sg" {
  source = "../aws_sg"
}

module "network" {
  source = "../aws_network"
}

resource "aws_elb" "this" {
  name = "web-elb"
  security_groups = [
    "${module.sg.elb_sg}"
  ]
  subnets = [
    "${module.network.public_subnet_ids}",
    "${module.network.private_subnet_ids}"
  ]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-Elb"
    }
  )
}