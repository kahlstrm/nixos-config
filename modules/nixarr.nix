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
  # give jellyfin access to GPU/render devices
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
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
      privateTrackers.disableDhtPex = true;
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
  services.nginx.virtualHosts."prowlarr.${acmeHost}" = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9696";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  services.nginx.virtualHosts."radarr.${acmeHost}" = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://127.0.0.1:7878";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };

  services.nginx.virtualHosts."sonarr.${acmeHost}" = {
    forceSSL = true;
    useACMEHost = acmeHost;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8989";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
