# Add output variables

output "vpc_id" {
  value = module.vpc-prod.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc-prod.public_subnet_ids[*]
}

output "private_subnet_ids" {
  value = module.vpc-prod.private_subnet_ids[*]
}