data "vault_kv_secret_v2" "vpc" {
    mount = "secret"
    name  = "terraform/vpc"
}

data "vault_kv_secret_v2" "subnets" {
    mount = "secret"
    name = "terraform/subnets"
}