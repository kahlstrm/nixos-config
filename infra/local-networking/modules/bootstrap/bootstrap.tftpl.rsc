# -----------------------------------------------------------------------------
#               GENERIC MIKROTIK BOOTSTRAP SCRIPT TEMPLATE
# -----------------------------------------------------------------------------
# This is a generic bootstrap script for RouterOS devices. Its purpose is to
# configure a device just enough to be managed by Terraform.
%{if false}
# THIS IS NOT VALID RouterOS Script, this is a terraform templatefile that will be used
# to generate valid files under generated/ and automatically uploaded to the approriate device
# during terraform apply
%{ endif }# -----------------------------------------------------------------------------

:global bootstrapMode;
:global isLocalBridgeCreated false;
:log info "Starting bootstrap script";

# ------------------------------------------------------------------------------
#                          USER-CONFIGURABLE PARAMETERS
# ------------------------------------------------------------------------------
# --- System Identity ---
:local systemIdentity "${system_identity}"

# --- Local LAN Configuration ---
:local localBridgeName "${local_bridge_name}"
:local localBridgePorts {${local_bridge_ports}}
:local localIpv6Address "${local_ipv6_address}"

# --- Transit Link Configuration ---
# This is a dedicated interface for the stationary<->kuberack wired link.
# Optional set transitInterface empty to disable
:local transitInterface "${transit_interface}"
:local transitIpv6AddressNetwork "${transit_ipv6_address_network}"

# --- WAN Configuration ---
:local wanInterface "${wan_interface}"
:local maintenancePort "${maintenance_port}"
# ------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#                            DERIVED PARAMETERS
#-------------------------------------------------------------------------------
:local createLocalBridge ([:len $localBridgePorts] > 0)
:local localIpv6Host [:pick $localIpv6Address 0 [:find $localIpv6Address "/"]]
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Apply configuration.
# these commands are executed after installation or configuration reset
#-------------------------------------------------------------------------------
/system identity set name=$systemIdentity

# wait for interfaces
:local count 0;
:while ([/interface ethernet find] = "") do={
  :if ($count = 30) do={
    :log warning "bootstrap: Unable to find ethernet interfaces";
    /quit;
  }
  :delay 1s; :set count ($count +1);
};
/interface list add name=WAN comment="bootstrap"
/interface list add name=LAN comment="bootstrap"
/interface list add name=MGMT_ALLOWED comment="bootstrap"

# --- Maintenance Port Setup ---
:if ($maintenancePort != "") do={
  /ip address add address=192.168.88.1/24 interface=$maintenancePort comment="bootstrap: maintenance"
  /ip pool add name=maintenance-pool ranges=192.168.88.10-192.168.88.254
  /ip dhcp-server add name=maintenance-dhcp interface=$maintenancePort address-pool=maintenance-pool disabled=no
  /ip dhcp-server network add address=192.168.88.0/24 gateway=192.168.88.1
  /interface list member add list=MGMT_ALLOWED interface=$maintenancePort comment="bootstrap: maintenance"
}

# --- Local Bridge Setup ---
# Create a bridge for the local LAN.
:if ($createLocalBridge) do={
  /interface bridge
    add name=$localBridgeName disabled=no protocol-mode=rstp comment="bootstrap";

  # Assign a stable MAC address from the first port in the list.
  :local firstPort [:pick $localBridgePorts 0];
  /interface bridge set $localBridgeName admin-mac=[/interface ethernet get $firstPort mac-address] auto-mac=no;

  # Add only the specified interfaces to the bridge.
  :foreach port in=$localBridgePorts do={
    /interface bridge port add bridge=$localBridgeName interface=$port comment=bootstrap;
  }

  # --- IP Setup for Local LAN ---
  /ip address add address=${local_ipv4_address} interface=$localBridgeName;
  /ipv6 address add address=$localIpv6Address interface=$localBridgeName advertise=yes comment="bootstrap";
  /ipv6 nd prefix default set autonomous=yes;
  /ipv6 nd disable [find default]
  # Terraform adopts this entry; keep advertisements off when IPv6 is disabled.
  /ipv6 nd add interface=$localBridgeName advertise-dns=${enable_ipv6 ? "yes" : "no"} dns="${enable_ipv6 ? split("/", local_ipv6_address)[0] : ""}" managed-address-configuration=no other-configuration=no disabled=${enable_ipv6 ? "no" : "yes"} ra-lifetime=${enable_ipv6 ? "30m" : "none"}

  /interface list member add list=LAN interface=$localBridgeName comment="bootstrap";

  # Set the flag to indicate the bridge was created.
  :set isLocalBridgeCreated true;
}

# --- Static DNS Records for All Routers ---
# Add records for all managed routers to solve provider DNS resolution.
%{ for name, ips in all_router_dns_records ~}
/ip dns static add name="${name}" address=${ips.ip} type=A
/ip dns static add name="${name}" address=${ips.ipv6} type=AAAA disabled=${ips.enable_ipv6 ? "no" : "yes"} comment="bootstrap"
%{ endfor ~}

# --- Transit Link Setup ---
:if ($transitInterface != "") do={
  /ip address add address=${transit_ipv4_address} interface=$transitInterface;
  /ipv6 address add address="$transitIpv6AddressNetwork" interface=$transitInterface comment="bootstrap: transit link";
  /interface list member add list=LAN interface=$transitInterface comment="bootstrap";
}

%{ if length(management_routes) > 0 ~}
# --- Management Routes ---
# Routes to reach other routers' management networks during bootstrap
%{ for route in management_routes ~}
/ip route add dst-address=${route.ipv4_destination} gateway=${route.ipv4_gateway} distance=1 check-gateway=ping comment="${route.ipv4_comment}"
/ipv6 route add dst-address=${route.ipv6_destination} gateway=${route.ipv6_gateway} distance=${route.distance} comment="bootstrap: ${route.comment}"
%{ endfor ~}
%{ endif ~}
#
# --- System Services ---
# Allow management access only from trusted interfaces.
:if ($createLocalBridge) do={
  /interface list member add list=MGMT_ALLOWED interface=$localBridgeName comment="bootstrap"
}
:if ($transitInterface != "") do={
  /interface list member add list=MGMT_ALLOWED interface=$transitInterface comment="bootstrap"
}
/ip neighbor discovery-settings set discover-interface-list=MGMT_ALLOWED
/tool mac-server set allowed-interface-list=MGMT_ALLOWED
/tool mac-server mac-winbox set allowed-interface-list=MGMT_ALLOWED

# --- Global Services ---
# IPv4 resolvers only: this is the pre-Terraform config, and unreachable resolvers cost
# real queries here (RouterOS spends attempts on them), which is enough to break the very
# first terraform init. Terraform adds the IPv6 resolvers when enable_ipv6 is set.
/ip dns set allow-remote-requests=yes servers=1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4
/ip dhcp-client add interface=$wanInterface disabled=no use-peer-dns=no comment="bootstrap"
/ipv6 settings set disable-ipv6=${enable_ipv6 ? "no" : "yes"} accept-router-advertisements=${enable_ipv6 ? "yes" : "no"} forward=${enable_ipv6 ? "yes" : "no"}
# The WAN prefix delegation and the LAN address taken from it are owned by modules/ipv6.
# Creating them here would leave Terraform unable to manage them without a per-device
# import, since this script only ever runs once at provisioning.
/certificate/settings set builtin-trust-store=all

/interface list member add list=WAN interface=$wanInterface comment="bootstrap"
%{for table in firewall_tables ~}
%{for rule in table.rules ~}
/${table.path} add ${join(" ", [for name, value in rule.properties : "${replace(name, "_", "-")}=${jsonencode(value)}"])}
%{endfor ~}
%{endfor ~}

/certificate {
  add name=ca common-name=local_ca key-usage=key-cert-sign
  add name=self common-name=localhost
  sign ca
  sign self
}

# there seems to be some race-condition with certificate signing and the ip service www-ssl enabling
# where the ip service doesn't always find the signed cert
# so let's make while loop to wait for 5s to find the certifcation
:local ms 0
:local timeout 5000
:while ([:len [/certificate find name="self"]] = 0 && $ms < $timeout) do={
    :delay 500ms
    :set ms ($ms + 500)
}
:if ([:len [/certificate find name="self"]] = 0) do={
    :log error ("Timeout waiting for certificate 'self' after " . $ms . " ms")
    :error "Timeout waiting for certificate 'self'"
}
:log info ("Found certificate 'self' after " . $ms . " ms")
/ip service set www-ssl certificate=self disabled=no
%{if install_zerotier}
# --- ZeroTier Installation ---
# Check if the ZeroTier package is installed and enabled. If not, find and install it.
# The device will reboot automatically to apply the changes.
:if ([/system package print count-only where name="zerotier" and disabled=no] > 0) do={
  :log info "ZeroTier package is already installed and enabled.";
} else={
  :log info "ZeroTier package not found or is disabled; attempting to install.";
  /system package update check-for-updates;
  :delay 5s;
  :if ([/system package print count-only where name="zerotier"] > 0) do={
      :log info "Found ZeroTier package, enabling it now.";
      /system package enable zerotier;
      :log info "Rebooting to apply package changes.";
      /log/print file=boostrap.txt
      :execute script="/system package apply-changes"
      :delay 1s; /quit;
  } else={
      :log warning "Could not find ZeroTier package after checking for updates.";
  }
}%{ endif }
# All bootstrap steps completed; the integration test checks this after reboot.
:log info bootstrap_script_finished;
:set bootstrapMode;
# reboot for ipv6 accept-router-advertisement setting to be enabled
:log info "Rebooting for ipv6 accept-router-advertisement change"
/log/print file=boostrap.txt
:execute script="/system reboot"
