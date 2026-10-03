data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "terraform-state-1751317459"
    prefix = "local-networking"
  }
}

locals {
  # Extract networking outputs to local variables
  k8s_controlplanes = data.terraform_remote_state.networking.outputs.k8s_controlplanes
  k8s_workers       = data.terraform_remote_state.networking.outputs.k8s_workers
  cluster_network   = data.terraform_remote_state.networking.outputs.cluster_network

  # Define cluster endpoint locally
  cluster_endpoint = "https://${values(data.terraform_remote_state.networking.outputs.k8s_controlplanes)[0].ip}:6443"
}
