# Variable to signal the current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}

variable "name" {
  default     = "alb"
  type        = string
  description = "Name of the Application Load Balancer"
}

variable "sg_id" {
  type        = string
  description = "security group id"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}