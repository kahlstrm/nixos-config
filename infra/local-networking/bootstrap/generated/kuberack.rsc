# -----------------------------------------------------------------------------
#               GENERIC MIKROTIK BOOTSTRAP SCRIPT TEMPLATE
# -----------------------------------------------------------------------------
# This is a generic bootstrap script for RouterOS devices. Its purpose is to
# configure a device just enough to be managed by Terraform.
# -----------------------------------------------------------------------------

:global bootstrapMode;
:global isLocalBridgeCreated false;
:log info "Starting bootstrap script";

# ------------------------------------------------------------------------------
#                          USER-CONFIGURABLE PARAMETERS
# ------------------------------------------------------------------------------
# --- System Identity ---
:local systemIdentity "kuberack"

# --- Local LAN Configuration ---
:local localBridgeName "kuberack-bridge"
:local localBridgePorts {"ether2"; "ether3"; "ether4"; "ether5"; "ether6"; "ether7"; "sfp-sfpplus1"}
:local localIpv6Address "fd00:de:ad:10::1/64"

# --- Transit Link Configuration ---
# This is a dedicated interface for the stationary<->kuberack wired link.
# Optional set transitInterface empty to disable
:local transitInterface "ether1"
:local transitIpv6AddressNetwork "fd00:de:ad:ff::1/64"

# --- WAN Configuration ---
:local wanInterface "ether8"
:local maintenancePort ""
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
  /ip address add address=10.10.10.1/24 interface=$localBridgeName;
  /ipv6 address add address=$localIpv6Address interface=$localBridgeName advertise=yes comment="bootstrap";
  /ipv6 nd prefix default set autonomous=yes;
  /ipv6 nd disable [find default]
  # Terraform adopts this entry; keep advertisements off when IPv6 is disabled.
  /ipv6 nd add interface=$localBridgeName advertise-dns=no dns="" managed-address-configuration=no other-configuration=no disabled=yes ra-lifetime=none

  /interface list member add list=LAN interface=$localBridgeName comment="bootstrap";

  # Set the flag to indicate the bridge was created.
  :set isLocalBridgeCreated true;
}

# --- Static DNS Records for All Routers ---
# Add records for all managed routers to solve provider DNS resolution.
/ip dns static add name="kuberack.networking.kalski.xyz" address=10.10.10.1 type=A
/ip dns static add name="kuberack.networking.kalski.xyz" address=fd00:de:ad:10::1 type=AAAA disabled=yes comment="bootstrap"
/ip dns static add name="stationary.networking.kalski.xyz" address=10.1.1.1 type=A
/ip dns static add name="stationary.networking.kalski.xyz" address=fd00:de:ad:1::1 type=AAAA disabled=yes comment="bootstrap"

# --- Transit Link Setup ---
:if ($transitInterface != "") do={
  /ip address add address=10.254.254.1/30 interface=$transitInterface;
  /ipv6 address add address="$transitIpv6AddressNetwork" interface=$transitInterface comment="bootstrap: transit link";
  /interface list member add list=LAN interface=$transitInterface comment="bootstrap";
}

# --- Management Routes ---
# Routes to reach other routers' management networks during bootstrap
/ip route add dst-address=10.1.1.0/24 gateway=10.254.254.2 distance=1 check-gateway=ping comment="Primary route to stationary LAN via transit link"
/ipv6 route add dst-address=fd00:de:ad:1::1/64 gateway=fd00:de:ad:ff::2 distance=255 comment="bootstrap: route to stationary for management"
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
/ipv6 settings set disable-ipv6=yes accept-router-advertisements=no forward=no
# The WAN prefix delegation and the LAN address taken from it are owned by modules/ipv6.
# Creating them here would leave Terraform unable to manage them without a per-device
# import, since this script only ever runs once at provisioning.
/certificate/settings set builtin-trust-store=all

/interface list member add list=WAN interface=$wanInterface comment="bootstrap"
/ip/firewall/nat add action="masquerade" chain="srcnat" comment="bootstrap: masquerade" ipsec-policy="out,none" out-interface-list="WAN"
/ip/firewall/filter add action="accept" chain="input" comment="bootstrap: accept established,related,untracked" connection-state="established,related,untracked"
/ip/firewall/filter add action="drop" chain="input" comment="bootstrap: drop invalid" connection-state="invalid"
/ip/firewall/filter add action="accept" chain="input" comment="bootstrap: accept ICMP" protocol="icmp"
/ip/firewall/filter add action="accept" chain="input" comment="bootstrap: accept to local loopback (for CAPsMAN)" dst-address="127.0.0.1"
/ip/firewall/filter add action="accept" chain="input" comment="bootstrap: allow incoming from MGMT_ALLOWED" in-interface-list="MGMT_ALLOWED"
/ip/firewall/filter add action="drop" chain="input" comment="bootstrap: drop all not coming from LAN" in-interface-list="!LAN"
/ip/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept in ipsec policy" ipsec-policy="in,ipsec"
/ip/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept out ipsec policy" ipsec-policy="out,ipsec"
/ip/firewall/filter add action="fasttrack-connection" chain="forward" comment="bootstrap: fasttrack" connection-state="established,related" in-interface-list="LAN" out-interface-list="LAN"
/ip/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept established,related, untracked" connection-state="established,related,untracked"
/ip/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop invalid" connection-state="invalid"
/ip/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop all from WAN not DSTNATed" connection-nat-state="!dstnat" connection-state="new" in-interface-list="WAN"
/ipv6/firewall/address-list add address="::/128" comment="bootstrap: unspecified address" list="bad_ipv6"
/ipv6/firewall/address-list add address="::1" comment="bootstrap: lo" list="bad_ipv6"
/ipv6/firewall/address-list add address="fec0::/10" comment="bootstrap: site-local" list="bad_ipv6"
/ipv6/firewall/address-list add address="::ffff:0.0.0.0/96" comment="bootstrap: ipv4-mapped" list="bad_ipv6"
/ipv6/firewall/address-list add address="::/96" comment="bootstrap: ipv4 compat" list="bad_ipv6"
/ipv6/firewall/address-list add address="100::/64" comment="bootstrap: discard only " list="bad_ipv6"
/ipv6/firewall/address-list add address="2001:db8::/32" comment="bootstrap: documentation" list="bad_ipv6"
/ipv6/firewall/address-list add address="2001:10::/28" comment="bootstrap: ORCHID" list="bad_ipv6"
/ipv6/firewall/address-list add address="3ffe::/16" comment="bootstrap: 6bone" list="bad_ipv6"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept established,related,untracked" connection-state="established,related,untracked"
/ipv6/firewall/filter add action="drop" chain="input" comment="bootstrap: drop invalid" connection-state="invalid"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept ICMPv6" protocol="icmpv6"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept UDP traceroute" dst-port="33434-33534" protocol="udp"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept DHCPv6-Client prefix delegation." dst-port="546" protocol="udp" src-address="fe80::/10"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept IKE" dst-port="500,4500" protocol="udp"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept ipsec AH" protocol="ipsec-ah"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept ipsec ESP" protocol="ipsec-esp"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: accept all that matches ipsec policy" ipsec-policy="in,ipsec"
/ipv6/firewall/filter add action="accept" chain="input" comment="bootstrap: allow incoming from MGMT_ALLOWED" in-interface-list="MGMT_ALLOWED"
/ipv6/firewall/filter add action="drop" chain="input" comment="bootstrap: drop everything else not coming from LAN" in-interface-list="!LAN"
/ipv6/firewall/filter add action="fasttrack-connection" chain="forward" comment="bootstrap: fasttrack6" connection-state="established,related" in-interface-list="LAN" out-interface-list="LAN"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept established,related,untracked" connection-state="established,related,untracked"
/ipv6/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop invalid" connection-state="invalid"
/ipv6/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop packets with bad src ipv6" src-address-list="bad_ipv6"
/ipv6/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop packets with bad dst ipv6" dst-address-list="bad_ipv6"
/ipv6/firewall/filter add action="drop" chain="forward" comment="bootstrap: rfc4890 drop hop-limit=1" hop-limit="equal:1" protocol="icmpv6"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept ICMPv6" protocol="icmpv6"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept HIP" protocol="139"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept IKE" dst-port="500,4500" protocol="udp"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept ipsec AH" protocol="ipsec-ah"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept ipsec ESP" protocol="ipsec-esp"
/ipv6/firewall/filter add action="accept" chain="forward" comment="bootstrap: accept all that matches ipsec policy" ipsec-policy="in,ipsec"
/ipv6/firewall/filter add action="drop" chain="forward" comment="bootstrap: drop everything else not coming from LAN" in-interface-list="!LAN"

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
}
# All bootstrap steps completed; the integration test checks this after reboot.
:log info bootstrap_script_finished;
:set bootstrapMode;
# reboot for ipv6 accept-router-advertisement setting to be enabled
:log info "Rebooting for ipv6 accept-router-advertisement change"
/log/print file=boostrap.txt
:execute script="/system reboot"
