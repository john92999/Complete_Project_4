locals {
    subnet_azs  =  split (",", data.vault_kv_secret_v2.subnets.data["subnet_availability_zone"])
    subnet_cidrs = split (",", data.vault_kv_secret_v2.subnets.data["subnet_cidr_block"])
}