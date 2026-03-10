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
    }

    assert {
        condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
        error_message = "cidr_block was not passed through correctly"
    }

    assert {
        condition     = module.vpc.vpc_tags["Name"] == "main-vpc"   
        error_message = "Name tag is wrong"
    }


}