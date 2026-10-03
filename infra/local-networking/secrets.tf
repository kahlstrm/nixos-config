module "secrets" {
  source      = "../modules/secrets"
  secret_name = "local-networking"
}

locals {
  config = module.secrets.secret_output_dict
}
