mock_provider "aws" {
    mock_resource "aws_vpc" {
        defaults = {
            id = "vpc-0abc123456789def0"
        }
    }
}

run "vpc_cidr_is_correct" {
    command = plan

    variables {
        region     = "ap-south-1"
        cidr_block = "10.0.0.0/16"
        Name       = "main-vpc"
        subnet_cidr_block = ["10.0.1.0/24", "10.0.2.0/24"]
        subnet_availability_zone = ["ap-south-1a", "ap-south-1b"]
    }

    assert {
        condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
        error_message = "cidr_block was not passed through correctly"
    }

    assert {
        condition     = module.vpc.vpc_tags["Name"] == "main-vpc"   
        error_message = "Name tag is wrong"
    }

    assert {
        condition = module.vpc.subnet_cidr_block == ["10.0.1.0/24", "10.0.2.0/24"]
        error_message = "subnet CIDR blocks are incorrect"
    }


}