{
  currentSystemUser,
  pkgs,
  config,
  ...
}:
let
  acmeMail = "kalle.ahlstrom@iki.fi";
  acmeHost = "zima.kalski.xyz";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/zima.nix
    (import ../modules/nixarr.nix {
      inherit acmeMail acmeHost;
      mediaDir = "/mnt/data/media";
      stateDir = "/mnt/data/media/.state/nixarr";
      wgConf = "/data/.secret/wg.conf";
      peerPort = 3666;
    })
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.fwupd.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # OpenSSH for remote administration
  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    description = "Kalle Ahlstrom";
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
  };

  environment.systemPackages = with pkgs; [ btrfs-progs ];

  security.acme = {
    acceptTerms = true;
    defaults.email = acmeMail;
    certs."zima.kalski.xyz" = {
      inherit (config.services.nginx) group;
      domain = acmeHost;
      dnsProvider = "cloudflare";
      credentialsFile = "/data/.secret/cloudflare.env";
      extraDomainNames = [ "*.${acmeHost}" ];
    };
    certs."jet.kalski.xyz" = {
      domain = "jet.kalski.xyz";
      dnsProvider = "cloudflare";
      credentialsFile = "/data/.secret/cloudflare.env";
      # Need to setup host root SSH-key and add public key to jetKVM for this to work
      # Settings -> Advanced
      # Developer Mode on
      # Then add key to "SSH Public key" list
      postRun = ''
        ${pkgs.openssh}/bin/ssh root@jet.kalski.xyz "mkdir -p /userdata/jetkvm/tls"
        cat fullchain.pem | ${pkgs.openssh}/bin/ssh root@jet.kalski.xyz "cat > /userdata/jetkvm/tls/user-defined.crt"
        cat key.pem | ${pkgs.openssh}/bin/ssh root@jet.kalski.xyz "cat > /userdata/jetkvm/tls/user-defined.key"
        ${pkgs.openssh}/bin/ssh root@jet.kalski.xyz "sed -i 's/\"tls_mode\": \"\"/\"tls_mode\": \"custom\"/' /userdata/kvm_config.json"
      '';
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
