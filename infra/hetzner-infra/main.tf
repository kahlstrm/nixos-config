data "hcloud_ssh_key" "mac_personal" {
  name = "mac-personal"
}

resource "hcloud_firewall" "ssh_only" {
  name = "ssh-only"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

locals {
  nixos_infect_cloud_config = <<-EOT
    #cloud-config

    runcmd:
      - ROOT_DEV=$(findmnt -n -o SOURCE /)
      - e2label "$ROOT_DEV" nixos
      - BOOT_DEV=$(findmnt -n -o SOURCE /boot/efi || findmnt -n -o SOURCE /boot)
      - '[ -n "$BOOT_DEV" ] && (fatlabel "$BOOT_DEV" boot || true)'
      - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-unstable bash 2>&1 | tee /tmp/infect.log
  EOT
}

resource "hcloud_firewall" "deny_all" {
  name = "deny-all"
}

resource "hcloud_firewall" "headscale" {
  name = "headscale"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "41641"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "3478"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "poenttoe" {
  name        = "poenttoe"
  location    = "hel1"
  server_type = "cpx22"
  image       = "ubuntu-24.04"

  ssh_keys           = [data.hcloud_ssh_key.mac_personal.id]
  firewall_ids       = concat([hcloud_firewall.deny_all.id, hcloud_firewall.headscale.id, hcloud_firewall.iperf.id], var.BOOTSTRAP ? [hcloud_firewall.ssh_only.id] : [])
  user_data          = local.nixos_infect_cloud_config
  delete_protection  = true
  rebuild_protection = true
  lifecycle {
    prevent_destroy = true
  }
}
