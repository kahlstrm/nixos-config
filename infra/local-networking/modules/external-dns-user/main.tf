terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

resource "routeros_system_user_group" "external_dns" {
  name   = "external-dns"
  policy = ["read", "write", "api", "rest-api"]
}

resource "routeros_system_user" "external_dns" {
  name     = "external-dns"
  password = var.external_dns_password
  group    = routeros_system_user_group.external_dns.name
}
