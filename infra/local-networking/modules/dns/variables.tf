variable "a_records" {
  type = map(object({
    ip                = string
    include_subdomain = optional(bool)
  }))
}

variable "use_adlist" {
  description = "Enable DNS adlists for blocking ads, trackers, and malicious domains"
  type        = bool
}

variable "use_doh_server" {
  description = "DNS-over-HTTPS endpoint URL. Set null to disable DoH."
  type        = string
  default     = null
}

variable "verify_doh_cert" {
  description = "Verify the TLS certificate of the DoH server using RouterOS trust store."
  type        = bool
  default     = true
}

variable "additional_dns_servers" {
  description = "Additional DNS servers that are going to be queried first before the others."
  type        = list(string)
  default     = []
}

variable "use_ipv6_dns" {
  description = "Include IPv6 upstream resolvers. Disable while WAN IPv6 is unavailable, as unreachable resolvers cause intermittent lookup timeouts."
  type        = bool
  default     = true
}
