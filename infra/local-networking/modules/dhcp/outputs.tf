output "dhcp_server_name" {
  description = "The name of the created DHCP server."
  value       = routeros_ip_dhcp_server.dhcp_server.name
}