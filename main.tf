module "vpc" {
    source = "./modules/vpc"
    region = local.region
    cidr_block = local.cidr_block
    Name = local.Name
    subnet_availability_zone = local.subnet_azs
    subnet_cidr_block = local.subnet_cidrs
}