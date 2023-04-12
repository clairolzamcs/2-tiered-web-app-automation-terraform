# ELB security group
output "elb_sg" {
  value = aws_security_group.elb.id
}