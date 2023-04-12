provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.env}-finalproj-group1"
    key    = "${var.env}/network/terraform.tfstate"
    region = "us-east-1"
  }
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

# Creating an Auto scaling group for webservers
resource "aws_autoscaling_group" "this" {
  name                 = "${local.name_prefix}-AutoScalingGroup"
  min_size             = var.min_capacity
  desired_capacity     = var.desired_capacity
  max_size             = var.max_capacity
  target_group_arns    = [var.target_group_arn]
  launch_configuration = var.launch_config_name
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

  tags = merge(
    local.default_tags,
    {
      "Name" = "${local.name_prefix}-Webserver"
    }
  )
}

#Policy to change autoscaling group according to alarm by cloudwatch
resource "aws_autoscaling_policy" "asg_policy_web_up" {
  name                   = "asg_policy_web_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.this.name
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
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
  alarm_description = "This metric monitors EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_web_up.arn]
}

resource "aws_autoscaling_policy" "asg_policy_web_down" {
  name                   = "asg_policy_web_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.this.name
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
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }
  alarm_description = "This metric monitors EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_web_down.arn]
}