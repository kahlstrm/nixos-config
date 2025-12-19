{
  ...
}:
let
  domain = "head.kalski.xyz";
  dnsFile = "/var/lib/headscale/dns.json";
in
{
  services.headscale = {
    enable = true;
    address = "[::]";
    port = 443;
    settings = {
      server_url = "https://${domain}";
      dns = {
        base_domain = "vpn.kalski.xyz";
        magic_dns = true;
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        extra_records_path = dnsFile;
      };
      # Path to the ACL policy
      policy.path = "/etc/headscale/acl.hujson";

      # Built-in TLS
      tls_letsencrypt_hostname = domain;
      tls_letsencrypt_challenge_type = "TLS-ALPN-01";
    };
  };
  # Initialize the DNS file if it doesn't exist
  systemd.services.headscale.preStart = ''
    if [ ! -f ${dnsFile} ]; then
      echo "[]" > ${dnsFile}
    fi
  '';

  # Define the ACL Policy
  environment.etc."headscale/acl.hujson".text = ''
    {
      "groups": {
        "group:admin": ["admin@kalski.xyz"]
      },
      "tagOwners": {
        "tag:https": ["group:admin"]
      },
      "acls": [
        // Allow all users to access nodes tagged with 'tag:https'
        // ONLY on port 443 (HTTPS)
        {
          "action": "accept",
          "src": ["*"],
          "dst": ["tag:https:443"]
        }
      ]
    }
  '';

  # Open firewall ports for Headscale (443) and DERP (UDP)
  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [ 41641 ];

  # Ensure headscale group exists
  users.groups.headscale = { };
}
