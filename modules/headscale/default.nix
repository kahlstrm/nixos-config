{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  domain = "head.kalski.xyz";
  dnsFile = "/var/lib/headscale/dns.json";
  cfg = config.services.headscale;
  runtimeConfig = "/run/headscale/config.json";
  baseConfig = (pkgs.formats.json { }).generate "headscale-base.json" (
    lib.filterAttrsRecursive (_: value: value != null) cfg.settings
  );
in
{
  age.secrets.headscale-oidc = {
    file = ../../secrets/headscale-oidc.age;
    owner = cfg.user;
    group = cfg.group;
    mode = "0400";
  };

  services.headscale = {
    enable = true;
    package = pkgs-unstable.headscale;
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
      # Embedded DERP Server (Relay + STUN)
      derp.server = {
        enabled = true;
        region_id = 999;
        region_code = "headscale";
        region_name = "Headscale";
        stun_listen_addr = "[::]:3478";
        verify_clients = true;
      };
    };
  };
  # Initialize the DNS file if it doesn't exist
  systemd.services.headscale.preStart = ''
    umask 077
    if ! ${lib.getExe pkgs.jq} -e -s '
      def nonempty: type == "string" and length > 0;
      if length == 2 and
         (.[1] | keys == ["oidc"]) and
         (.[1].oidc | type == "object") and
         (.[1].oidc | [.issuer, .client_id, .client_secret] | all(.[]; nonempty)) and
         (.[1].oidc.allowed_users | type == "array" and length > 0 and all(.[]; nonempty))
      then .[0] * .[1]
      else error("Invalid OIDC configuration") end
    ' ${baseConfig} ${config.age.secrets.headscale-oidc.path} > ${runtimeConfig}.tmp 2>/dev/null; then
      rm -f ${runtimeConfig}.tmp
      echo "Headscale OIDC configuration is missing or invalid; refusing to start" >&2
      exit 1
    fi
    mv -f ${runtimeConfig}.tmp ${runtimeConfig}
    if [ ! -f ${dnsFile} ]; then
      echo "[]" > ${dnsFile}
    fi
  '';
  # Keep decrypted settings out of the Nix store; the upstream module uses a store config.
  systemd.services.headscale.script = lib.mkForce ''
    exec ${lib.getExe cfg.package} serve --config ${runtimeConfig}
  '';
  systemd.services.headscale.restartTriggers = [
    config.age.secrets.headscale-oidc.file
    config.environment.etc."headscale/acl.hujson".source
  ];
  # Define the ACL Policy
  environment.etc."headscale/acl.hujson".text = ''
    {
      "groups": {
        "group:admin": ["admin@kalski.xyz"]
      },
      "tagOwners": {
        "tag:https": ["zima@kalski.xyz"],
        "tag:ark": ["pannu@kalski.xyz"]
      },
      "acls": [
        // Allow all users to access nodes tagged with 'tag:https'
        // ONLY on port 443 (HTTPS)
        {
          "action": "accept",
          "src": ["*"],
          "dst": ["tag:https:443"]
        },
        // Allow all users to access nodes tagged with 'tag:ark'
        // UDP game port (7777)
        {
          "action": "accept",
          "src": ["*"],
          "dst": ["tag:ark:7777"],
          "proto": "udp"
        },
        // TCP RCON port (27020)
        {
          "action": "accept",
          "src": ["*"],
          "dst": ["tag:ark:27020"],
          "proto": "tcp"
        }
      ]
    }
  '';

  # Open firewall ports for Headscale (443), DERP/WireGuard (41641), and STUN (3478)
  networking.firewall.allowedTCPPorts = [ 443 ];
  networking.firewall.allowedUDPPorts = [
    41641
    3478
  ];

  # Ensure headscale group exists
  users.groups.headscale = { };

}
