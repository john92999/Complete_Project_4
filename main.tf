module "vpc" {
    source = "./modules/vpc"
    region = var.region
    cidr_block = var.cidr_block
    Name = var.Name
}