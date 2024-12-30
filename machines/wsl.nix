{ currentSystemUser, ... }:
{
  imports = [ ];

  wsl = {
    enable = true;
    defaultUser = currentSystemUser;
    startMenuLaunchers = true;
  };

  system.stateVersion = "24.05";
}
