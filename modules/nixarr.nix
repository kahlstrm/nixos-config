{
  acmeHost,
  acmeMail,
  peerPort,
  wgConf,
  mediaDir,
  stateDir,
}:
{
  resolvedModules,
  lib,
  ...
}:
{
  imports = [
    resolvedModules.nixarr
  ];

  nixarr = {
    enable = true;
    inherit mediaDir stateDir;
    vpn = {
      enable = true;
      # install this file
      wgConf = wgConf;
      # for debugging VPN
      # vpnTestService = {
      #   enable = true;
      #   port = vpnPort;
      # };
    };

    transmission = {
      enable = true;
      vpn.enable = true;
      peerPort = peerPort;
    };

    jellyfin = {
      enable = true;
      expose.https = {
        enable = true;
        domainName = "jellyfin.${acmeHost}";
        acmeMail = acmeMail;
      };
      openFirewall = false; # rely on nginx only
    };

    jellyseerr = {
      enable = true;
      expose.https = {
        enable = true;
        domainName = "jellyseerr.${acmeHost}";
        acmeMail = acmeMail;
      };
      openFirewall = false; # rely on nginx only
    };

    sonarr = {
      enable = true;
      openFirewall = false;
    };
    radarr = {
      enable = true;
      openFirewall = false;
    };
    bazarr = {
      enable = true;
      openFirewall = false;
    };
    prowlarr = {
      enable = true;
      openFirewall = false;
    };
  };
  # Reuse your existing wildcard cert for zima.kalski.xyz
  services.nginx.virtualHosts."jellyfin.${acmeHost}" = {
    enableACME = lib.mkForce false;
    useACMEHost = acmeHost;
  };
  services.nginx.virtualHosts."jellyseerr.${acmeHost}" = {
    enableACME = lib.mkForce false;
    useACMEHost = acmeHost;
  };
}
