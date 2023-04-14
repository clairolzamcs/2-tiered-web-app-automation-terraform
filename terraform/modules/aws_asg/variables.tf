variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}

variable "name" {
  default     = "asg"
  type        = string
  description = "Name of the Auto Scaling Group"
}


variable "target_group_arn" {
  type        = string
  description = "calling load_balancers id"
}

variable "launch_config_name" {
  type        = string
  description = "calling template_name from launch config"
}

variable "min_capacity" {
  default     = 1
  type        = number
  description = "Minimum capacity of Auto scaling group"
}

variable "max_capacity" {
  default     = 4
  type        = number
  description = "Maximum capacity of Auto scaling group"
}

variable "desired_capacity" {
  default     = 2
  type        = number
  description = "Desired capacity of Auto scaling group"
}