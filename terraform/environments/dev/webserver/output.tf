output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "bastion_sg_id" {
  value = module.bastion-sg.sg_id
}

output "web_alb_name" {
  value = module.web-alb.name
}