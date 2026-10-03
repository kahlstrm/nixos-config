terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

# Continuous ICMP probes so intermittent WAN packet loss is visible after the fact rather
# than only while someone happens to be watching. RouterOS records loss-percent, rtt-avg
# and rtt-jitter per probe, and mktxp's netwatch collector is already enabled, so these
# reach Prometheus without deploying another exporter.
resource "routeros_tool_netwatch" "probe" {
  for_each = var.targets

  name            = each.key
  host            = each.value
  type            = "icmp"
  interval        = var.interval
  packet_count    = var.packet_count
  packet_interval = var.packet_interval
  comment         = "terraform: wan loss probe"
}
