output "talosconfig" {
  description = "Talos client configuration"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes client configuration"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = try(data.kubernetes_secret.argocd_initial_admin_secret.data["password"], null)
  sensitive   = true
}