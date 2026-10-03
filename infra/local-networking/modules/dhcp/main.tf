terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

# Creates the DHCP server, bound to the specified interface.
resource "routeros_ip_dhcp_server" "dhcp_server" {
  name            = var.dhcp_server_name
  interface       = var.interface_name
  address_pool    = length(routeros_ip_pool.dhcp_pool) > 0 ? routeros_ip_pool.dhcp_pool[0].name : null
  disabled        = var.disabled
  use_reconfigure = true
  lease_time      = var.lease_time
  lifecycle {
    ignore_changes = [disabled, dynamic_lease_identifiers]
  }
}

resource "routeros_ip_dhcp_server_network" "dhcp_server_network" {
  address    = var.network_address
  gateway    = var.gateway_ip
  dns_server = var.dns_servers
}

resource "routeros_ip_pool" "dhcp_pool" {
  count  = var.pool_ranges != null ? 1 : 0
  name   = var.dhcp_server_name
  ranges = var.pool_ranges
}

resource "routeros_ip_dhcp_server_lease" "static_lease" {
  for_each    = var.static_leases
  mac_address = each.value.mac_address
  address     = each.value.ip
  comment     = each.key
  server      = routeros_ip_dhcp_server.dhcp_server.name
}
