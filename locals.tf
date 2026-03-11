locals {
    region = data.vault_kv_secret_v2.vpc.data["region"]
    cidr_block = data.vault_kv_secret_v2.vpc.data["cidr_block"]
    Name = data.vault_kv_secret_v2.vpc.data["Name"]
    subnet_azs  =  split (",", data.vault_kv_secret_v2.subnets.data["subnet_availability_zone"])
    subnet_cidrs = split (",", data.vault_kv_secret_v2.subnets.data["subnet_cidr_block"])
}