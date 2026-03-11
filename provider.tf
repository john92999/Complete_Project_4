provider "aws" {
    region = "ap-south-1"
}

provider "vault" {
  address = "http://10.48.17.203:8200"
  # need to add token here
}