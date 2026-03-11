variable "region" {
    description = "region of the aws VPC"
    type = string
}

variable "cidr_block" {
    description = "value of the VPC cidr"
    type = string
}

variable "Name" {
    description = "name of the VPC_CIDR"
    type = string
}

variable "subnet_availability_zone" {
    description = "Where the subnetes are"
    type = list(string)
}

variable "subnet_cidr_block" {
    description = "Aubntes of the cidr block"
    type = list(string)
}