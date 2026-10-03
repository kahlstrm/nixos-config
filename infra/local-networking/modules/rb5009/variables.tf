variable "config" {
  type = object({
    ip                = string
    transit_address   = string
    transit_interface = string
  })
}

variable "lan_static_leases" {
  type = map(object({
    ip          = string
    mac_address = string
  }))
}

variable "bridge_interface" {
  description = "The name of the main LAN bridge interface."
  type        = string
}

variable "lan_dhcp_config" {
  type = object({
    server_name     = string
    network_address = string
    pool_ranges     = list(string)
  })
}

variable "dns_a_records" {
  type = map(object({
    ip                = string
    include_subdomain = optional(bool)
  }))
}

variable "wan_interface" {
  type = string
}

variable "cake_disabled" {
  type    = bool
  default = false
}

variable "cake_down_mbps" {
  type    = number
  default = 800
}

variable "cake_up_mbps" {
  type    = number
  default = 80
}

variable "enable_cake" {
  description = "Enable CAKE QoS on WAN interface"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 globally, including local addressing, WAN prefix delegation, router advertisements, and IPv6 DNS."
  type        = bool
  default     = true
}

variable "netwatch_targets" {
  description = "ICMP probe targets for WAN loss/latency monitoring, keyed by probe name. mktxp's netwatch collector is already enabled, so these reach Prometheus without an extra exporter."
  type        = map(string)
  default = {
    cloudflare-dns = "1.1.1.1"
    google-dns     = "8.8.8.8"
  }
}

variable "ipv6_prefix_hint" {
  description = "Prefix size to request from the ISP, e.g. \"::/56\". Null omits the hint."
  type        = string
  default     = null
}
