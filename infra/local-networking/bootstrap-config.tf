locals {
  bootstrap_configs = {
    "stationary" = {
      system_identity              = "stationary"
      enable_ipv6                  = local.stationary.enable_ipv6
      transit_ipv4_address         = local.stationary.transit_address
      local_bridge_name            = "local-bridge"
      local_bridge_ports           = ["ether2", "ether3", "ether4", "ether5", "ether6", "sfp-sfpplus1"]
      maintenance_port             = "ether7"
      local_ipv4_address           = format("%s/24", local.stationary.ip)
      local_ipv6_address           = format("%s/64", local.stationary.ipv6)
      all_router_dns_records       = local.all_router_dns_records
      transit_interface            = local.stationary.transit_interface
      transit_ipv6_address_network = "${local.stationary.transit_ipv6}/64"
      wan_interface                = local.stationary.wan_interface
      cake_enabled                 = local.stationary.enable_cake
      install_zerotier             = true
      management_routes = [
        {
          peer             = "kuberack"
          comment          = "route to kuberack for management"
          ipv4_destination = local.kuberack_network.network
          ipv4_gateway     = split("/", local.kuberack.transit_address)[0]
          ipv6_destination = format("%s/64", local.kuberack.ipv6)
          ipv6_gateway     = local.kuberack.transit_ipv6
          distance         = 255
        }
      ]
    },
    "kuberack" = {
      system_identity              = "kuberack"
      enable_ipv6                  = local.kuberack.enable_ipv6
      transit_ipv4_address         = local.kuberack.transit_address
      local_bridge_name            = "kuberack-bridge"
      local_bridge_ports           = ["ether2", "ether3", "ether4", "ether5", "ether6", "ether7", "sfp-sfpplus1"]
      maintenance_port             = ""
      local_ipv4_address           = format("%s/24", local.kuberack.ip)
      local_ipv6_address           = format("%s/64", local.kuberack.ipv6)
      all_router_dns_records       = local.all_router_dns_records
      transit_interface            = local.kuberack.transit_interface
      transit_ipv6_address_network = "${local.kuberack.transit_ipv6}/64"
      wan_interface                = local.kuberack.wan_interface
      cake_enabled                 = local.kuberack.enable_cake
      install_zerotier             = true
      management_routes = [
        {
          peer             = "stationary"
          comment          = "route to stationary for management"
          ipv4_destination = local.stationary_lan.network
          ipv4_gateway     = split("/", local.stationary.transit_address)[0]
          ipv6_destination = format("%s/64", local.stationary.ipv6)
          ipv6_gateway     = local.stationary.transit_ipv6
          distance         = 255
        }
      ]
    }
  }
}
