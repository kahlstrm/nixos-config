terraform {
  required_providers {
    routeros = {
      source                = "terraform-routeros/routeros"
      configuration_aliases = [routeros.stationary]
    }
  }
}

module "rb5009" {
  source = "../rb5009"

  providers = {
    routeros = routeros.stationary
  }

  config            = var.config.device_config
  lan_dhcp_config   = var.config.dhcp_config
  lan_static_leases = var.config.static_leases
  bridge_interface  = var.config.bridge_interface
  dns_a_records     = var.config.dns_a_records
  wan_interface     = var.config.wan_interface
  enable_cake       = var.config.enable_cake
  cake_disabled     = false
  cake_down_mbps    = var.config.cake_down_mbps
  cake_up_mbps      = var.config.cake_up_mbps
  enable_ipv6       = var.config.enable_ipv6
  ipv6_prefix_hint  = var.config.ipv6_prefix_hint
  netwatch_targets  = var.config.netwatch_targets
}
