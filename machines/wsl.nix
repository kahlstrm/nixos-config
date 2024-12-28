{ currentSystemUser, ... }:
{
  imports = [ ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = currentSystemUser;
    startMenuLaunchers = true;
  };

  system.stateVersion = "24.11";
}
