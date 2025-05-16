{ ... }:
{
  nix.gc.interval = {
    Weekday = 0; # Sunday
    Hour = 0;
    Minute = 0;
  };
  nix.settings.sandbox = true;
  nix.settings.trusted-users = [ "@admin" ];
}
