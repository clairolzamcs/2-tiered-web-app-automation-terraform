output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_sg_id" {
  value = module.bastion-sg.sg_id
}


output "alb_dns_name" {
  value = aws_lb.web_lb.name
}