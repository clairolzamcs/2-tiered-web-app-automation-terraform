# ALB security group
output "alb_sg" {
  value = aws_security_group.alb.id
}