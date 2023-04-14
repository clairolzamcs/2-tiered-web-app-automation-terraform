provider "aws" {
  region = "us-east-1"
}

module "globalvars" {
  source = "../../../modules/globalvars"
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

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.env}-finalproj-group1"
    key    = "${var.env}/network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_instance_profile" "lab_instance_profile" {
  name = "LabInstanceProfile"
}

# Webserver Module Security Group
module "web-sg" {
  source = "../../../modules/aws_sg"
  env    = var.env
  name   = "webserver"
  desc   = "webserver-security-group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

# Application Load Balancer Module Security Group
module "alb-sg" {
  source = "../../../modules/aws_sg"
  env    = var.env
  name   = "alb"
  desc   = "alb-security-group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}
# Bastion Module Security Group
module "bastion-sg" {
  source = "../../../modules/aws_sg"
  env    = var.env
  name   = "bastion"
  desc   = "bastion-security-group"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress_rules = [{
    description = "SSH from private IP of Cloud9 machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_private_ip}/32", "${var.my_public_ip}/32"]
  }]
}

# Webserver Launch Configuration
module "web-launch-config" {
  source        = "../../../modules/aws_launchconfig"
  env           = var.env
  name          = "web-launch-config"
  keypair_path  = aws_key_pair.web_key.key_name
  instance_type = var.instance_type
  sg_id         = module.web-sg.sg_id
}

# Web Server Auto Scaling Group 
module "web-asg" {
  source             = "../../../modules/aws_asg"
  env                = var.env
  name               = "autoscaling-group"
  target_group_arn   = module.web-alb.tg_arn
  launch_config_name = module.web-launch-config.launch_config_name
}


# Webserver Application Load Balancer
module "web-alb" {
  source        = "../../../modules/aws_alb"
  env           = var.env
  name          = "web"
  instance_type = var.instance_type
  sg_id         = module.web-sg.sg_id
}

# Bastion deployment in Public Subnet 1
module "bastion" {
  source        = "../../../modules/aws_bastion"
  env           = var.env
  keypair_path  = aws_key_pair.web_key.key_name
  instance_type = var.instance_type
  sg_id         = module.bastion-sg.sg_id
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}
