output "vpc_id" {
    value = aws_vpc.main-vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main-vpc.cidr_block
}

output "vpc_tags" {
  value = aws_vpc.main-vpc.tags
}

output "subnet_cidr_block" {
  value = aws_subnet.all-subnets[*].cidr_block
}