output "vpc_id" {
  value = module.vpc.vpc_id
  sensitive = true
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
  sensitive = true
}

output "vpc_tags" {
  value = module.vpc.vpc_tags
  sensitive = true
}
