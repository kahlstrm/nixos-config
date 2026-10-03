module "secrets" {
  source      = "../modules/secrets"
  secret_name = "hetzner-infra"
}

locals {
  config = module.secrets.secret_output_dict
}

