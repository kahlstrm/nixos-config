variable "account_key_pem" {
  description = "The account key for ACME provider."
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "The domain to issue the certificate for."
  type        = string
}

variable "cf_dns_api_token" {
  description = "The Cloudflare DNS API token."
  type        = string
  sensitive   = true
}
