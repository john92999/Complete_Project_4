resource "aws_vpc" "main-vpc" {
    region = var.region
    cidr_block = var.cidr_block

    tags = {
        Name = var.Name
    }
}