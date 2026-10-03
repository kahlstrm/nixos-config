data "cloudflare_zone" "kalski_xyz" {
  filter = {
    name = "kalski.xyz"
  }
}

resource "cloudflare_dns_record" "headscale_a" {
  zone_id = data.cloudflare_zone.kalski_xyz.id
  name    = "head"
  content = hcloud_server.poenttoe.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 300
}

resource "cloudflare_dns_record" "headscale_aaaa" {
  zone_id = data.cloudflare_zone.kalski_xyz.id
  name    = "head"
  content = hcloud_server.poenttoe.ipv6_address
  type    = "AAAA"
  proxied = false
  ttl     = 300
}