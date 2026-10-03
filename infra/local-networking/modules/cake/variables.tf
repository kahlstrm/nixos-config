variable "name" {
  type    = string
  default = "wan-cake"
}
variable "wan_interface" { type = string }
variable "disabled" {
  type    = bool
  default = false
}
# run test in https://www.waveform.com/tools/bufferbloat and put in them numbres
# keep lowering until you get +1 ms max on both
variable "down_mbps" { type = number }
variable "up_mbps" { type = number }

# Allowed: ethernet, ether-vlan, pppoe, pppoe-vlan, ptm, atm, docsis
variable "wan_type" {
  type = string
  validation {
    condition     = contains(["ethernet", "ether-vlan", "pppoe", "pppoe-vlan", "ptm", "atm", "docsis"], var.wan_type)
    error_message = "wan_type must be one of: ethernet, ether-vlan, pppoe, pppoe-vlan, ptm, atm, docsis."
  }
}

variable "ack_filter" {
  type    = string
  default = "filter"
  validation {
    condition     = contains(["filter", "", "aggressive"], var.ack_filter)
    error_message = "ack_filter must be one of: filter, '', aggressive."
  }
}
