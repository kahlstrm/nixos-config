output "secret_id" {
  description = "Google Secret Manager secret ID for this layer"
  value       = module.secrets.secret_id
}

output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.poenttoe.id
}

output "server_ipv4" {
  description = "Public IPv4 address"
  value       = hcloud_server.poenttoe.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address"
  value       = hcloud_server.poenttoe.ipv6_address
}
