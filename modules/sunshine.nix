{
  hostname ? null,
  acmeHost,
}:
{ lib, ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      origin_web_ui_allowed = "pc";
    }
    // lib.optionalAttrs (hostname != null) {
      csrf_allowed_origins = "https://${hostname}";
    };
  };

  services.nginx = lib.mkIf (hostname != null) {
    enable = true;
    virtualHosts.${hostname} = {
      locations."/" = {
        proxyPass = "https://127.0.0.1:47990";
        proxyWebsockets = true;
      };
      forceSSL = true;
      useACMEHost = acmeHost;
    };
  };
}
