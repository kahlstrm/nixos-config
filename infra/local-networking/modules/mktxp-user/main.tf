terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

resource "routeros_system_user_group" "mktxp" {
  name   = var.group_name
  policy = var.policies
}

resource "routeros_system_user" "mktxp" {
  name     = var.username
  password = var.password
  group    = routeros_system_user_group.mktxp.name
}
