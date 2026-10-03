output "network_id" {
  value = zerotier_network.network.id
}

output "poenttoe_private_key" {
  value     = zerotier_identity.poenttoe.private_key
  sensitive = true
}

output "poenttoe_public_key" {
  value = zerotier_identity.poenttoe.public_key
}
