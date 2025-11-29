{ ... }:
{
  nix.gc.interval = {
    Weekday = 0; # Sunday
    Hour = 0;
    Minute = 0;
  };
  nix.settings.sandbox = true;
  nix.settings.trusted-users = [ "@admin" ];
  launchd.daemons.nix-gc.serviceConfig = {
    StandardOutPath = "/var/log/nix-gc.log";
    StandardErrorPath = "/var/log/nix-gc.log";
  };
}
