resource "aws_vpc" "main-vpc" {
    region = var.region
    cidr_block = var.cidr_block

    tags = {
        Name = var.Name
    }
}

resource "aws_subnet" "all-subnets"{
    count = length(var.subnet_cidr_block)
    vpc_id = aws_vpc.main-vpc.id
    availability_zone = var.subnet_availability_zone[count.index]
    cidr_block = var.subnet_cidr_block[count.index]
}