module "bootstrap_stationary" {
  source           = "./modules/bootstrap"
  providers        = { routeros = routeros.stationary }
  config           = local.bootstrap_configs.stationary
  output_directory = "${path.root}/bootstrap/generated"
}

module "bootstrap_kuberack" {
  source           = "./modules/bootstrap"
  providers        = { routeros = routeros.kuberack }
  config           = local.bootstrap_configs.kuberack
  output_directory = "${path.root}/bootstrap/generated"
}

locals {
  bootstrap_adoption = {
    bindings = flatten([for site, bindings in {
      stationary = module.bootstrap_stationary.adoption
      kuberack   = module.bootstrap_kuberack.adoption
      } : [for binding in bindings : merge(binding, {
        router  = site
        address = "module.bootstrap_${site}.${binding.address}"
    })]])
    routers = {
      stationary = {
        url      = var.stationary_hosturl
        username = local.config["stationary_rb5009"]["username"]
        password = local.config["stationary_rb5009"]["password"]
        insecure = var.ALLOW_INSECURE
      }
      kuberack = {
        url      = var.kuberack_hosturl
        username = local.config["kuberack_rb5009"]["username"]
        password = local.config["kuberack_rb5009"]["password"]
        insecure = var.ALLOW_INSECURE
      }
    }
  }
}
