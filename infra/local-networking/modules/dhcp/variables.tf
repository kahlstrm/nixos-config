variable "dhcp_server_name" {
  description = "The name for the DHCP server."
  type        = string
}

variable "interface_name" {
  description = "The interface to bind the DHCP server to."
  type        = string
}

variable "network_address" {
  description = "The network address for the DHCP server."
  type        = string
}

variable "gateway_ip" {
  description = "The gateway IP address for DHCP clients."
  type        = string
}

variable "dns_servers" {
  description = "List of DNS server IP addresses."
  type        = list(string)
}

variable "disabled" {
  description = "Whether the DHCP server should be disabled initially."
  type        = bool
  default     = false
}

variable "pool_ranges" {
  description = "DHCP pool ranges e.g.  [\"10.0.0.100-10.0.0.200\"]"
  type        = list(string)
  nullable    = true
}

variable "static_leases" {
  description = "Static leases for the DHCP server"
  type = map(object({
    ip          = string
    mac_address = string
  }))
}

variable "lease_time" {
  description = "lease_time in time duration"
  default     = "30m"
}
