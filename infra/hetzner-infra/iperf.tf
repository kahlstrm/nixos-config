resource "hcloud_firewall" "iperf" {
  name = "poenttoe-iperf"

  rule {
    description = "iperf tests from stationary"
    direction   = "in"
    protocol    = "tcp"
    port        = "5201-5202"
    source_ips  = local.config["iperf"]["source_cidrs"]
  }
}
