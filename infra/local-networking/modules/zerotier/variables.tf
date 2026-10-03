variable "kuberack" {
  type = object({
    ip            = string
    zerotier_ip   = string
    wan_interface = string
  })
}

variable "stationary" {
  type = object({
    ip            = string
    zerotier_ip   = string
    wan_interface = string
  })
}

variable "poenttoe_ip" {
  type = string
}
