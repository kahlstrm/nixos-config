# STATE_BUCKET=terraform-state-$(date +%s)
# gsutil mb gs://$STATE_BUCKET
# gsutil versioning set on gs://$STATE_BUCKET
terraform {
  backend "gcs" {
    bucket = "terraform-state-1751317459"
    prefix = "local-talos"
  }
}
