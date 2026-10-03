# Advertising a default route with broken WAN IPv6 causes client delays.
# Without explicit client routes, withdrawing it also loses cross-site ULA access.
resource "routeros_ipv6_settings" "this" {
  disable_ipv6                 = !var.config.enable_ipv6
  forward                      = var.config.enable_ipv6
  accept_router_advertisements = var.config.enable_ipv6 ? "yes" : "no"
}

resource "routeros_ipv6_neighbor_discovery" "lan" {
  interface                     = var.config.local_bridge_name
  disabled                      = !var.config.enable_ipv6
  advertise_dns                 = var.config.enable_ipv6
  dns                           = var.config.enable_ipv6 ? split("/", var.config.local_ipv6_address)[0] : ""
  managed_address_configuration = false
  other_configuration           = false
  ra_lifetime                   = var.config.enable_ipv6 ? "30m" : "none"
}

resource "routeros_ip_dns_record" "aaaa" {
  for_each = local.records
  name     = each.key
  type     = "AAAA"
  address  = each.value.ipv6
  disabled = !each.value.enable_ipv6
  comment  = "bootstrap"
}

locals {
  ipv6_adoption = concat([
    { address = "routeros_ipv6_settings.this", path = "ipv6/settings", match = {} },
    { address = "routeros_ipv6_neighbor_discovery.lan", path = "ipv6/nd", match = { interface = var.config.local_bridge_name } }
    ], [for name, record in local.records : {
      address = "routeros_ip_dns_record.aaaa[${jsonencode(name)}]"
      path    = "ip/dns/static"
      match   = { name = name, type = "AAAA", address = record.ipv6 }
  }])
}
