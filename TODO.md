# TODO

- [ ] Migrate MinIO root/Loki and Harbor admin passwords in
  [kubernetes-secrets.tf](infra/local-talos/kubernetes-secrets.tf) to ephemeral
  Terraform resources and write-only Kubernetes Secret fields so credentials
  are not stored in Terraform state.
