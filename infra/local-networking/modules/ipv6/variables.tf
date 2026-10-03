variable "wan_interface" {
  description = "WAN interface the DHCPv6-PD client runs on."
  type        = string
}

variable "enable_ipv6" {
  description = "Enable IPv6 globally, including local addressing, WAN prefix delegation, router advertisements, and IPv6 DNS."
  type        = bool
}

variable "bridge_interface" {
  description = "LAN bridge that receives a /64 out of the delegated prefix."
  type        = string
}

variable "pool_name" {
  description = "IPv6 pool the delegated prefix is written into. Must match the pool the bridge address takes its prefix from."
  type        = string
  default     = "wan-ipv6-pool"
}

variable "prefix_hint" {
  description = "Prefix size to request from the ISP, e.g. \"::/56\". The ISP documents a /56 with a prefix hint. Null omits the hint."
  type        = string
  default     = null
}
