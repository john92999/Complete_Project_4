module "vpc" {
    source = "./modules/vpc"
    region = var.region
    cidr_block = var.cidr_block
    Name = var.Name
    subnet_availability_zone = var.subnet_availability_zone
    subnet_cidr_block = var.subnet_cidr_block
}