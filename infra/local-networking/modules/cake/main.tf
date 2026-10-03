terraform {
  required_providers {
    routeros = { source = "terraform-routeros/routeros" }
  }
}

locals {
  # hard fail on unknown
  overhead_scheme_map = {
    ethernet   = "ethernet"
    ether-vlan = "ether-vlan"
    pppoe      = "pppoe"
    pppoe-vlan = "pppoe-vlan"
    ptm        = "ptm"
    atm        = "atm"
    docsis     = "docsis"
  }
  cake_overhead_scheme = local.overhead_scheme_map[var.wan_type]
  cake_mpu             = var.wan_type == "docsis" ? 64 : 0

  down_limit = "${ceil(var.down_mbps)}M"
  up_limit   = "${ceil(var.up_mbps)}M"
}

# Ingress (download)
resource "routeros_queue_type" "cake_rx" {
  name                 = "${var.name}-rx"
  kind                 = "cake"
  cake_diffserv        = "diffserv4"
  cake_flowmode        = "dual-dsthost"
  cake_nat             = true
  cake_overhead_scheme = local.cake_overhead_scheme
  cake_mpu             = local.cake_mpu
}

# Egress (upload)
resource "routeros_queue_type" "cake_tx" {
  name                 = "${var.name}-tx"
  kind                 = "cake"
  cake_diffserv        = "diffserv4"
  cake_flowmode        = "dual-srchost"
  cake_nat             = true
  cake_overhead_scheme = local.cake_overhead_scheme
  cake_mpu             = local.cake_mpu
  cake_ack_filter      = var.ack_filter
}

resource "routeros_queue_simple" "wan_cake" {
  disabled    = var.disabled
  name        = var.name
  target      = [var.wan_interface]
  max_limit   = "${local.down_limit}/${local.up_limit}"
  queue       = "${routeros_queue_type.cake_rx.name}/${routeros_queue_type.cake_tx.name}"
  bucket_size = "0.001/0.001"
}
