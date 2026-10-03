terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

module "dhcp_lan" {
  source           = "../dhcp"
  dhcp_server_name = var.lan_dhcp_config.server_name
  interface_name   = var.bridge_interface
  network_address  = var.lan_dhcp_config.network_address
  gateway_ip       = var.config.ip
  dns_servers      = [var.config.ip]
  pool_ranges      = var.lan_dhcp_config.pool_ranges
  static_leases    = var.lan_static_leases
}

module "dns" {
  source       = "../dns"
  a_records    = var.dns_a_records
  use_adlist   = true
  use_ipv6_dns = var.enable_ipv6
}

# Read the default gateway from the routing table; it may be another local router.
data "routeros_ip_routes" "default" {
  filter = {
    dst_address = "0.0.0.0/0"
  }
}

module "netwatch" {
  source = "../netwatch"
  targets = merge(
    var.netwatch_targets,
    try({ "default-gateway" = data.routeros_ip_routes.default.routes[0].gateway }, {}),
  )
}

module "ipv6" {
  source           = "../ipv6"
  wan_interface    = var.wan_interface
  bridge_interface = var.bridge_interface
  enable_ipv6      = var.enable_ipv6
  prefix_hint      = var.ipv6_prefix_hint
}

module "cake" {
  disabled      = var.cake_disabled
  count         = var.enable_cake ? 1 : 0
  source        = "../cake/"
  down_mbps     = var.cake_down_mbps
  up_mbps       = var.cake_up_mbps
  wan_interface = var.wan_interface
  wan_type      = "docsis"
}
