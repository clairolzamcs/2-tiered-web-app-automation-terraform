variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}

variable "env" {
  default     = "Dev"
  type        = string
  description = "Deployment Environment"
}

variable "asg_desired_capacity" {
  default     = 2
  type        = string
  description = "Desired capacity of auto scaling group"
}
