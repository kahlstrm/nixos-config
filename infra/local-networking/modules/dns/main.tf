terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}
resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  cache_size            = var.use_adlist ? 40960 : 2048
  use_doh_server        = var.use_doh_server
  verify_doh_cert       = var.verify_doh_cert
  servers = concat(
    var.additional_dns_servers,
    [
      # Cloudflare
      "1.1.1.1",
      "1.0.0.1",
      # Google
      "8.8.8.8",
      "8.8.4.4",
    ],
    var.use_ipv6_dns ? [
      "2606:4700:4700::1111",
      "2606:4700:4700::1001",
      "2001:4860:4860::8888",
      "2001:4860:4860::8844",
    ] : []
  )
}


resource "routeros_ip_dns_record" "a_record" {
  for_each        = var.a_records
  type            = "A"
  address         = each.value.ip
  match_subdomain = each.value.include_subdomain == true
  name            = each.key
}


resource "routeros_ip_dns_adlist" "stevenblack" {
  count      = var.use_adlist ? 1 : 0
  url        = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
  ssl_verify = false
}

# TODO:
# - DoH? https://help.mikrotik.com/docs/spaces/ROS/pages/37748767/DNS#DNS-dohDNSoverHTTPS(DoH)
