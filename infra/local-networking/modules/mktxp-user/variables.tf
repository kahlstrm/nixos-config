variable "username" {
  description = "Service account username for mktxp"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Service account password for mktxp"
  type        = string
  sensitive   = true
}

variable "group_name" {
  description = "RouterOS user group name for mktxp permissions"
  type        = string
  default     = "mktxp"
}

variable "policies" {
  description = "RouterOS policy set for mktxp access"
  type        = list(string)
  default     = ["read", "api", "rest-api"]
}
