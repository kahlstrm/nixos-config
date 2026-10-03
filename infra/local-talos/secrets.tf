data "google_secret_manager_secret_version" "config" {
  secret = data.terraform_remote_state.networking.outputs.secret_id
}

locals {
  config = jsondecode(data.google_secret_manager_secret_version.config.secret_data)
}
