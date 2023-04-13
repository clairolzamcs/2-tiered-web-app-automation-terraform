# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

output "alb_dns_name" {
  value = aws_lb.web_lb.name
}