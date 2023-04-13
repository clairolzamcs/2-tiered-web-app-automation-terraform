# Variable to signal the current environment 
variable "env" {
  default     = "Dev"
  type        = string
  description = "Deployment Environment"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}

variable "prefix" {
  type        = string
  description = "Name prefix"
}

variable "sg_id" {
  type        = string
  description = "Webserver security group id"
}