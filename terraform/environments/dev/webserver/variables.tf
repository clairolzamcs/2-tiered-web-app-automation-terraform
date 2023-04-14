variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}

variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}

variable "asg_desired_capacity" {
  default     = 2
  type        = string
  description = "Desired capacity of auto scaling group"
}

variable "owner" {
  default     = "Group1"
  type        = string
  description = "Name of owner"
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

variable "my_private_ip" {
  type        = string
  description = "Private IP of my Cloud 9 station to be opened in bastion ingress"
  default     = "172.31.4.127"
}

variable "my_public_ip" {
  type        = string
  description = "Public IP of my Cloud 9 station to be opened in bastion ingress"
  default     = "52.3.235.18"
}