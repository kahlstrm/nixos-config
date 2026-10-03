variable "targets" {
  description = "ICMP probe targets keyed by probe name. Compare the default gateway with independent public resolvers to help locate loss along the path."
  type        = map(string)
}

variable "interval" {
  description = "How often each probe runs."
  type        = string
  default     = "30s"
}

variable "packet_count" {
  description = "Packets per probe run. This is the loss-percent denominator, so too few makes the figure coarse."
  type        = number
  default     = 20
}

variable "packet_interval" {
  description = "Spacing between packets within a probe run."
  type        = string
  default     = "100ms"
}
