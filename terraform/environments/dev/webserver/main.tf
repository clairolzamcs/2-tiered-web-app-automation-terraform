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
    bucket = "${var.env}-finalproj-group1-czcs"
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

# Webserver Launch Configuration
module "web-launch-config" {
  source        = "../../../modules/aws_launchconfig"
  env           = var.env
  name          = "web-launch-config"
  keypair_path  = aws_key_pair.web_key.key_name
  instance_type = var.instance_type
  sg_id         = module.web-sg.sg_id
}

# Creating an Auto scaling group for webservers
resource "aws_autoscaling_group" "web_asg" {
  name                 = "${local.name_prefix}-AutoScalingGroup"
  min_size             = var.min_capacity
  desired_capacity     = var.desired_capacity
  max_size             = var.max_capacity
  target_group_arns    = [module.web-alb.tg_arn]
  launch_configuration = module.web-launch-config.launch_config_name
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier = data.terraform_remote_state.network.outputs.private_subnet_ids

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-Webserver"
    propagate_at_launch = true
  }
}

#Policy to change autoscaling group according to alarm by cloudwatch
resource "aws_autoscaling_policy" "asg_policy_web_up" {
  name                   = "asg_policy_web_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

#Configuring an alarm to be fired when the total CPU utilization of all instances in our Auto Scaling Group will be the greater or equal to 10% during 120 seconds.
resource "aws_cloudwatch_metric_alarm" "metric_alarm_cpu_web_up" {
  alarm_name          = "metric_alarm_cpu_web_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_description = "This metric monitors EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_web_up.arn]
}

resource "aws_autoscaling_policy" "asg_policy_web_down" {
  name                   = "asg_policy_web_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

#Configuring an alarm to be fired when the total CPU utilization of all instances in our Auto Scaling Group will be the less than or equal to 5% during 120 seconds.
resource "aws_cloudwatch_metric_alarm" "metric_alarm_cpu_web_down" {
  alarm_name          = "metric_alarm_cpu_web_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_description = "This metric monitors EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_web_down.arn]
}

# Webserver Launch Configuration
module "web-alb" {
  source        = "../../../modules/aws_alb"
  env           = var.env
  name          = "web"
  instance_type = var.instance_type
  sg_id         = module.web-sg.sg_id
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

# Bastion Instance Deployment
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  security_groups             = [module.bastion-sg.sg_id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion"
    }
  )
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}
