module "vpc" {
    source = "./modules/vpc"
    region = local.region
    cidr_block = local.cidr_block
    Name = local.Name
    subnet_availability_zone = local.subnet_azs
    subnet_cidr_block = local.subnet_cidrs
}

module "s3" {
    source = "./modules/s3"
}

resource "aws_dynamodb_table" "Terraform_state_lock" {
    region = "ap-south-1"
    name = "terraform-state-lock"
    attribute {
        name = "LockID"
        type = "S"
    }
    hash_key = "LockID"
    billing_mode = "PAY_PER_REQUEST"
}