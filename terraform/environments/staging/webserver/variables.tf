variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}

variable "env" {
  default     = "staging"
  type        = string
  description = "Staging Environment"
}

variable "asg_desired_capacity" {
  default     = 3
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
  default     = 3
  type        = number
  description = "Desired capacity of Auto scaling group"
}
