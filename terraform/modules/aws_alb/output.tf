# Application Load balancer Outputs

output "name" {
  value = aws_lb.this.name
}

output "tg_arn" {
  value = aws_lb_target_group.this.arn
}