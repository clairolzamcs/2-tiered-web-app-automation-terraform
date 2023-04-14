# Variable to signal the current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}

variable "instance_type" {
  default     = "t3.micro"
  description = "Type of the instance"
  type        = string
}

variable "sg_id" {
  type        = string
  description = "security group id"
}

# This is a variable that is used to store the path to the keypair file.
variable "keypair_path" {
  default     = ""
  type        = string
  description = "File path where keypair is located"
}