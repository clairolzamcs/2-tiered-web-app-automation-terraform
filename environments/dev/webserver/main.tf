provider "aws" {
  region = "us-east-1"
}

# module "vpc-dev" {
#   source              = "../../../modules/aws_network"
#   env                 = var.env
#   vpc_cidr            = var.vpc_cidr
#   public_cidr_blocks  = var.public_cidr_blocks
#   private_cidr_blocks = var.private_cidr_blocks
# }

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

# Creating Security Group for web instances
resource "aws_security_group" "sg_web" {
  name        = "Web Security Group"
  description = "Security Group for Web"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
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
      "Name" = "${local.name_prefix}-Web-Sg"
    }
  )
}

resource "aws_launch_configuration" "web_launchconfig" {
  name                 = "${local.name_prefix}-LaunchConfig"
  image_id             = data.aws_ami.latest_amazon_linux.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.sg_web.id]
  key_name             = aws_key_pair.web_key.key_name
  iam_instance_profile = data.aws_iam_instance_profile.lab_instance_profile.name
  user_data = templatefile("${path.module}/install_httpd.sh.tpl",
    {
      name   = var.owner,
      env    = var.env,
      prefix = local.prefix
    }
  )
  root_block_device {
    encrypted = true
  }

  #added to enable Instance Metadata Service V2 (checkov error)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}

data "aws_iam_instance_profile" "lab_instance_profile" {
  name = "LabInstanceProfile"
}

# Creating an Auto scaling group for webservers
resource "aws_autoscaling_group" "web_asg" {
  name                 = "${local.name_prefix}-AutoScalingGroup"
  min_size             = var.min_capacity
  desired_capacity     = var.desired_capacity
  max_size             = var.max_capacity
  target_group_arns    = [aws_lb_target_group.web_lb_target_group.arn]
  launch_configuration = aws_launch_configuration.web_launchconfig.name
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

  tag  {
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

# Create AWS ALB
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.sg_web.id
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
resource "aws_lb_target_group" "web_lb_target_group" {
  name     = "web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
}

# Create listener
resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_lb_target_group.arn
  }
}

# Creating Security Group for bastion instances
resource "aws_security_group" "sg_bastion" {
  name        = "Bastion Security Group"
  description = "Security Group for Bastion"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # Inbound Rules
  ingress {
    description = "SSH from private IP of Cloud9 machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_private_ip}/32", "${var.my_public_ip}/32"]
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
      "Name" = "${local.name_prefix}-Bastion-Sg"
    }
  )
}

# Bastion deployment
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  security_groups             = [aws_security_group.sg_bastion.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      Name = "my_bastion"
    }
  )
}















# # Deploy security groups 
# module "sg-dev" {
#   source       = "../../../modules/aws_sg"
#   env          = var.env
# }

# # Deploy application load balancer
# module "alb-dev" {
#   source = "../../../modules/aws_alb"
#   env    = var.env
# }

# # Deploy webserver launch configuration
# module "launch-config-dev" {
#   source        = "../../../modules/aws_launchconfig"
#   env           = var.env
#   # sg_id         = module.sg-dev.web_sg_id
#   instance_type = var.instance_type
# }

# #Deploy auto scaling group
# module "autoscaling-group-dev" {
#   source             = "../../../modules/aws_asg"
#   # prefix             = module.globalvars.prefix
#   desired_capacity   = var.asg_desired_capacity
#   target_group_arn   = module.alb-dev.aws_lb_target_group_arn
#   launch_config_name = module.launch-config-dev.launch_config_name
# }

# locals {
#   default_tags = merge(module.globalvars.default_tags, { "Env" = var.env })
#   name_prefix  = "${module.globalvars.prefix}-${var.env}"
# }

# # Data source for AMI id to use for Bastion
# data "aws_ami" "latest_amazon_linux" {
#   owners      = ["amazon"]
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# # #Deploy Bastion Host
# # resource "aws_instance" "bastion" {
# #   ami                         = data.aws_ami.latest_amazon_linux.id
# #   instance_type               = var.instance_type
# #   key_name                    = local.name_prefix
# #   subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
# #   security_groups             = [module.security-group-dev.bastion_sg_id]
# #   associate_public_ip_address = true

# #   root_block_device {
# #     encrypted = true
# #   }

# #   lifecycle {
# #     create_before_destroy = true
# #   }
# #   tags = merge(local.default_tags, {
# #     Name = "${local.name_prefix}-Bastion"
# #     }
# #   )
# # }

# resource "aws_key_pair" "web_key" {
#   key_name   = local.name_prefix
#   public_key = file("${local.name_prefix}.pub")
# }

