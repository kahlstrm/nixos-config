locals {
  ipv4_nat = [
    {
      key = "srcnat_masquerade"
      properties = {
        chain              = "srcnat"
        out_interface_list = "WAN"
        ipsec_policy       = "out,none"
        action             = "masquerade"
        comment            = "bootstrap: masquerade"
      }
    },
  ]
  ipv4_filter = [
    {
      key = "input_accept_established_related_untracked"
      properties = {
        chain            = "input"
        action           = "accept"
        connection_state = "established,related,untracked"
        comment          = "bootstrap: accept established,related,untracked"
      }
    },
    {
      key = "input_drop_invalid"
      properties = {
        chain            = "input"
        action           = "drop"
        connection_state = "invalid"
        comment          = "bootstrap: drop invalid"
      }
    },
    {
      key = "input_accept_icmp"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "icmp"
        comment  = "bootstrap: accept ICMP"
      }
    },
    {
      key = "input_accept_to_local_loopback_for_capsman"
      properties = {
        chain       = "input"
        action      = "accept"
        dst_address = "127.0.0.1"
        comment     = "bootstrap: accept to local loopback (for CAPsMAN)"
      }
    },
    {
      key = "input_allow_incoming_from_mgmt_allowed"
      properties = {
        chain             = "input"
        action            = "accept"
        in_interface_list = "MGMT_ALLOWED"
        comment           = "bootstrap: allow incoming from MGMT_ALLOWED"
      }
    },
    {
      key = "input_drop_all_not_coming_from_lan"
      properties = {
        chain             = "input"
        action            = "drop"
        in_interface_list = "!LAN"
        comment           = "bootstrap: drop all not coming from LAN"
      }
    },
    {
      key = "forward_accept_in_ipsec_policy"
      properties = {
        chain        = "forward"
        action       = "accept"
        ipsec_policy = "in,ipsec"
        comment      = "bootstrap: accept in ipsec policy"
      }
    },
    {
      key = "forward_accept_out_ipsec_policy"
      properties = {
        chain        = "forward"
        action       = "accept"
        ipsec_policy = "out,ipsec"
        comment      = "bootstrap: accept out ipsec policy"
      }
    },
    {
      key = "forward_fasttrack"
      properties = merge({
        chain            = "forward"
        action           = "fasttrack-connection"
        connection_state = "established,related"
        comment          = "bootstrap: fasttrack"
      }, var.config.cake_enabled ? { in_interface_list = "LAN", out_interface_list = "LAN" } : {})
    },
    {
      key = "forward_accept_established_related_untracked"
      properties = {
        chain            = "forward"
        action           = "accept"
        connection_state = "established,related,untracked"
        comment          = "bootstrap: accept established,related, untracked"
      }
    },
    {
      key = "forward_drop_invalid"
      properties = {
        chain            = "forward"
        action           = "drop"
        connection_state = "invalid"
        comment          = "bootstrap: drop invalid"
      }
    },
    {
      key = "forward_drop_all_from_wan_not_dstnated"
      properties = {
        chain                = "forward"
        action               = "drop"
        connection_state     = "new"
        connection_nat_state = "!dstnat"
        in_interface_list    = "WAN"
        comment              = "bootstrap: drop all from WAN not DSTNATed"
      }
    },
  ]
  ipv6_addresses = [
    {
      key = "address_unspecified_address"
      properties = {
        list    = "bad_ipv6"
        address = "::/128"
        comment = "bootstrap: unspecified address"
      }
    },
    {
      key = "address_lo"
      properties = {
        list    = "bad_ipv6"
        address = "::1"
        comment = "bootstrap: lo"
      }
    },
    {
      key = "address_site_local"
      properties = {
        list    = "bad_ipv6"
        address = "fec0::/10"
        comment = "bootstrap: site-local"
      }
    },
    {
      key = "address_ipv4_mapped"
      properties = {
        list    = "bad_ipv6"
        address = "::ffff:0.0.0.0/96"
        comment = "bootstrap: ipv4-mapped"
      }
    },
    {
      key = "address_ipv4_compat"
      properties = {
        list    = "bad_ipv6"
        address = "::/96"
        comment = "bootstrap: ipv4 compat"
      }
    },
    {
      key = "address_discard_only"
      properties = {
        list    = "bad_ipv6"
        address = "100::/64"
        comment = "bootstrap: discard only "
      }
    },
    {
      key = "address_documentation"
      properties = {
        list    = "bad_ipv6"
        address = "2001:db8::/32"
        comment = "bootstrap: documentation"
      }
    },
    {
      key = "address_orchid"
      properties = {
        list    = "bad_ipv6"
        address = "2001:10::/28"
        comment = "bootstrap: ORCHID"
      }
    },
    {
      key = "address_6bone"
      properties = {
        list    = "bad_ipv6"
        address = "3ffe::/16"
        comment = "bootstrap: 6bone"
      }
    },
  ]
  ipv6_filter = [
    {
      key = "input_accept_established_related_untracked"
      properties = {
        chain            = "input"
        action           = "accept"
        connection_state = "established,related,untracked"
        comment          = "bootstrap: accept established,related,untracked"
      }
    },
    {
      key = "input_drop_invalid"
      properties = {
        chain            = "input"
        action           = "drop"
        connection_state = "invalid"
        comment          = "bootstrap: drop invalid"
      }
    },
    {
      key = "input_accept_icmpv6"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "icmpv6"
        comment  = "bootstrap: accept ICMPv6"
      }
    },
    {
      key = "input_accept_udp_traceroute"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "udp"
        dst_port = "33434-33534"
        comment  = "bootstrap: accept UDP traceroute"
      }
    },
    {
      key = "input_accept_dhcpv6_client_prefix_delegation"
      properties = {
        chain       = "input"
        action      = "accept"
        protocol    = "udp"
        dst_port    = "546"
        src_address = "fe80::/10"
        comment     = "bootstrap: accept DHCPv6-Client prefix delegation."
      }
    },
    {
      key = "input_accept_ike"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "udp"
        dst_port = "500,4500"
        comment  = "bootstrap: accept IKE"
      }
    },
    {
      key = "input_accept_ipsec_ah"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "ipsec-ah"
        comment  = "bootstrap: accept ipsec AH"
      }
    },
    {
      key = "input_accept_ipsec_esp"
      properties = {
        chain    = "input"
        action   = "accept"
        protocol = "ipsec-esp"
        comment  = "bootstrap: accept ipsec ESP"
      }
    },
    {
      key = "input_accept_all_that_matches_ipsec_policy"
      properties = {
        chain        = "input"
        action       = "accept"
        ipsec_policy = "in,ipsec"
        comment      = "bootstrap: accept all that matches ipsec policy"
      }
    },
    {
      key = "input_allow_incoming_from_mgmt_allowed"
      properties = {
        chain             = "input"
        action            = "accept"
        in_interface_list = "MGMT_ALLOWED"
        comment           = "bootstrap: allow incoming from MGMT_ALLOWED"
      }
    },
    {
      key = "input_drop_everything_else_not_coming_from_lan"
      properties = {
        chain             = "input"
        action            = "drop"
        in_interface_list = "!LAN"
        comment           = "bootstrap: drop everything else not coming from LAN"
      }
    },
    {
      key = "forward_fasttrack6"
      properties = merge({
        chain            = "forward"
        action           = "fasttrack-connection"
        connection_state = "established,related"
        comment          = "bootstrap: fasttrack6"
      }, var.config.cake_enabled ? { in_interface_list = "LAN", out_interface_list = "LAN" } : {})
    },
    {
      key = "forward_accept_established_related_untracked"
      properties = {
        chain            = "forward"
        action           = "accept"
        connection_state = "established,related,untracked"
        comment          = "bootstrap: accept established,related,untracked"
      }
    },
    {
      key = "forward_drop_invalid"
      properties = {
        chain            = "forward"
        action           = "drop"
        connection_state = "invalid"
        comment          = "bootstrap: drop invalid"
      }
    },
    {
      key = "forward_drop_packets_with_bad_src_ipv6"
      properties = {
        chain            = "forward"
        action           = "drop"
        src_address_list = "bad_ipv6"
        comment          = "bootstrap: drop packets with bad src ipv6"
      }
    },
    {
      key = "forward_drop_packets_with_bad_dst_ipv6"
      properties = {
        chain            = "forward"
        action           = "drop"
        dst_address_list = "bad_ipv6"
        comment          = "bootstrap: drop packets with bad dst ipv6"
      }
    },
    {
      key = "forward_rfc4890_drop_hop_limit_1"
      properties = {
        chain     = "forward"
        action    = "drop"
        protocol  = "icmpv6"
        hop_limit = "equal:1"
        comment   = "bootstrap: rfc4890 drop hop-limit=1"
      }
    },
    {
      key = "forward_accept_icmpv6"
      properties = {
        chain    = "forward"
        action   = "accept"
        protocol = "icmpv6"
        comment  = "bootstrap: accept ICMPv6"
      }
    },
    {
      key = "forward_accept_hip"
      properties = {
        chain    = "forward"
        action   = "accept"
        protocol = "139"
        comment  = "bootstrap: accept HIP"
      }
    },
    {
      key = "forward_accept_ike"
      properties = {
        chain    = "forward"
        action   = "accept"
        protocol = "udp"
        dst_port = "500,4500"
        comment  = "bootstrap: accept IKE"
      }
    },
    {
      key = "forward_accept_ipsec_ah"
      properties = {
        chain    = "forward"
        action   = "accept"
        protocol = "ipsec-ah"
        comment  = "bootstrap: accept ipsec AH"
      }
    },
    {
      key = "forward_accept_ipsec_esp"
      properties = {
        chain    = "forward"
        action   = "accept"
        protocol = "ipsec-esp"
        comment  = "bootstrap: accept ipsec ESP"
      }
    },
    {
      key = "forward_accept_all_that_matches_ipsec_policy"
      properties = {
        chain        = "forward"
        action       = "accept"
        ipsec_policy = "in,ipsec"
        comment      = "bootstrap: accept all that matches ipsec policy"
      }
    },
    {
      key = "forward_drop_everything_else_not_coming_from_lan"
      properties = {
        chain             = "forward"
        action            = "drop"
        in_interface_list = "!LAN"
        comment           = "bootstrap: drop everything else not coming from LAN"
      }
    },
  ]
  firewall_tables = {
    ipv4_nat       = { path = "ip/firewall/nat", resource = "routeros_ip_firewall_nat", rules = local.ipv4_nat }
    ipv4_filter    = { path = "ip/firewall/filter", resource = "routeros_ip_firewall_filter", rules = local.ipv4_filter }
    ipv6_addresses = { path = "ipv6/firewall/address-list", resource = "routeros_ipv6_firewall_addr_list", rules = local.ipv6_addresses }
    ipv6_filter    = { path = "ipv6/firewall/filter", resource = "routeros_ipv6_firewall_filter", rules = local.ipv6_filter }
  }
  firewall_adoption = flatten([for name, table in local.firewall_tables : [for rule in table.rules : {
    address = "${table.resource}.${name}[${jsonencode(rule.key)}]"
    path    = table.path
    match = merge({ comment = rule.properties.comment, dynamic = "false" },
    name == "ipv6_addresses" ? { list = rule.properties.list } : { chain = rule.properties.chain })
  }]])
}

resource "routeros_ip_firewall_nat" "ipv4_nat" {
  for_each           = { for rule in local.ipv4_nat : rule.key => rule.properties }
  action             = lookup(each.value, "action", null)
  chain              = lookup(each.value, "chain", null)
  comment            = lookup(each.value, "comment", null)
  ipsec_policy       = lookup(each.value, "ipsec_policy", null)
  out_interface_list = lookup(each.value, "out_interface_list", null)
}

resource "routeros_ip_firewall_filter" "ipv4_filter" {
  for_each             = { for rule in local.ipv4_filter : rule.key => rule.properties }
  action               = lookup(each.value, "action", null)
  chain                = lookup(each.value, "chain", null)
  comment              = lookup(each.value, "comment", null)
  connection_nat_state = lookup(each.value, "connection_nat_state", null)
  connection_state     = lookup(each.value, "connection_state", null)
  dst_address          = lookup(each.value, "dst_address", null)
  in_interface_list    = lookup(each.value, "in_interface_list", null)
  ipsec_policy         = lookup(each.value, "ipsec_policy", null)
  protocol             = lookup(each.value, "protocol", null)
  out_interface_list   = lookup(each.value, "out_interface_list", null)
}

resource "routeros_move_items" "ipv4_filter" {
  resource_path = "/ip/firewall/filter"
  sequence      = [for rule in local.ipv4_filter : routeros_ip_firewall_filter.ipv4_filter[rule.key].id]
}

resource "routeros_ipv6_firewall_addr_list" "ipv6_addresses" {
  for_each = { for rule in local.ipv6_addresses : rule.key => rule.properties }
  address  = lookup(each.value, "address", null)
  comment  = lookup(each.value, "comment", null)
  list     = lookup(each.value, "list", null)
}

resource "routeros_ipv6_firewall_filter" "ipv6_filter" {
  for_each           = { for rule in local.ipv6_filter : rule.key => rule.properties }
  action             = lookup(each.value, "action", null)
  chain              = lookup(each.value, "chain", null)
  comment            = lookup(each.value, "comment", null)
  connection_state   = lookup(each.value, "connection_state", null)
  dst_address_list   = lookup(each.value, "dst_address_list", null)
  dst_port           = lookup(each.value, "dst_port", null)
  hop_limit          = lookup(each.value, "hop_limit", null)
  in_interface_list  = lookup(each.value, "in_interface_list", null)
  ipsec_policy       = lookup(each.value, "ipsec_policy", null)
  protocol           = lookup(each.value, "protocol", null)
  src_address        = lookup(each.value, "src_address", null)
  src_address_list   = lookup(each.value, "src_address_list", null)
  out_interface_list = lookup(each.value, "out_interface_list", null)
}

resource "routeros_move_items" "ipv6_filter" {
  resource_path = "/ipv6/firewall/filter"
  sequence      = [for rule in local.ipv6_filter : routeros_ipv6_firewall_filter.ipv6_filter[rule.key].id]
}
