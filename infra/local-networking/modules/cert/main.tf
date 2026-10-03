terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
    acme = {
      source = "vancluever/acme"
    }
  }
}


locals {
  # Let's Encrypt returns issuer_pem as a chain: an intermediate plus a cross-signed root.
  # Both must be served - clients trust ISRG Root X1 rather than Root YR, so dropping the
  # cross-sign yields "unable to get local issuer certificate". RouterOS stores every
  # certificate of a PEM under one name and the provider cannot then address it, so each
  # element gets its own resource below.
  issuer_pems = [
    for pem in regexall("(?s)-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----", acme_certificate.cert.issuer_pem) : "${pem}\n"
  ]
}

resource "acme_certificate" "cert" {
  account_key_pem = var.account_key_pem
  common_name     = var.domain

  dns_challenge {
    provider = "cloudflare"
    config = {
      CF_DNS_API_TOKEN = var.cf_dns_api_token
    }
  }
}

resource "routeros_system_certificate" "external" {
  # RouterOS binds /ip service to a certificate's internal id, not its name, so a stable
  # name leaves www-ssl and api-ssl on the destroyed cert after a renewal and kills HTTPS.
  # The per-issuance suffix gives those services a real diff, and create_before_destroy
  # keeps the binding valid throughout. Hash certificate_url, not the sensitive pem.
  name        = "${acme_certificate.cert.common_name}-${substr(sha256(acme_certificate.cert.certificate_url), 0, 8)}.crt"
  common_name = acme_certificate.cert.common_name
  import {
    cert_file_content = acme_certificate.cert.certificate_pem
    key_file_content  = acme_certificate.cert.private_key_pem
  }
  lifecycle {
    create_before_destroy = true
  }
}

# The chain keeps stable names and no create_before_destroy: RouterOS deduplicates
# certificates by content, so importing the unchanged cross-sign while the old copy still
# exists is a no-op and the provider fails with "resource not found". The cost is a
# sub-second incomplete chain mid-renewal, which never affects the leaf rotation above.
resource "routeros_system_certificate" "external_issuer" {
  name        = "${acme_certificate.cert.common_name}.issuer.crt"
  common_name = "issuer"
  import {
    cert_file_content = local.issuer_pems[0]
  }
  lifecycle {
    ignore_changes = [common_name]
  }
}

resource "routeros_system_certificate" "external_issuer_cross" {
  name        = "${acme_certificate.cert.common_name}.issuer-cross.crt"
  common_name = "issuer"
  import {
    cert_file_content = local.issuer_pems[1]
  }
  lifecycle {
    ignore_changes = [common_name]
    # Asserted here rather than in count, which cannot depend on a value that is unknown
    # until apply.
    precondition {
      condition     = length(local.issuer_pems) == 2
      error_message = "Expected a 2-certificate issuer chain from Let's Encrypt, got ${length(local.issuer_pems)}; add a resource per extra element."
    }
  }
}

# Enable HTTPS WebFig with that cert; disable plain HTTP
resource "routeros_ip_service" "www" {
  numbers  = "www"
  port     = 80
  disabled = true
}

resource "routeros_ip_service" "api_ssl" {
  numbers     = "api-ssl"
  certificate = routeros_system_certificate.external.name
  port        = 8729
  disabled    = false
}

resource "routeros_ip_service" "www_ssl" {
  numbers     = "www-ssl"
  certificate = routeros_system_certificate.external.name
  port        = 443
  disabled    = false
}
