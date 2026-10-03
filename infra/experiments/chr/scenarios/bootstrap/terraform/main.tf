terraform {
  required_providers {
    routeros = { source = "terraform-routeros/routeros" }
    local    = { source = "hashicorp/local" }
  }
}

variable "stationary_hosturl" { type = string }
variable "kuberack_hosturl" { type = string }
variable "stationary_password" {
  type      = string
  sensitive = true
}
variable "kuberack_password" {
  type      = string
  sensitive = true
}
variable "ALLOW_INSECURE" { default = true }

provider "routeros" {
  alias    = "stationary"
  hosturl  = var.stationary_hosturl
  username = "admin"
  password = var.stationary_password
  insecure = var.ALLOW_INSECURE
}
provider "routeros" {
  alias    = "kuberack"
  hosturl  = var.kuberack_hosturl
  username = "admin"
  password = var.kuberack_password
  insecure = var.ALLOW_INSECURE
}
locals {
  config = {
    stationary_rb5009 = { username = "admin", password = var.stationary_password }
    kuberack_rb5009   = { username = "admin", password = var.kuberack_password }
  }
}
