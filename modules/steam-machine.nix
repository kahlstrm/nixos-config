{
  hasAmdGPU ? false,
}:
{
  currentSystemUser,
  pkgs,
  lib,
  ...
}:
let
  compatPaths = lib.makeSearchPathOutput "steamcompattool" "" (with pkgs; [ proton-ge-bin ]);
in
{
  users.groups."steam-machine" = { };
  users.users."steam-machine" = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "video"
      "input"
      "games"
    ];
    group = "steam-machine";
    packages = with pkgs; [
      firefox
      mpv
    ];
  };

  # if there is disk with label 'games', mounts it
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  # and makes it group writeable and changes group to 'games'
  systemd.services.setup-games-perms = {
    after = [ "mnt-games.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      chgrp games /mnt/games
      chmod 775 /mnt/games
      chmod g+s /mnt/games
    '';
  };

  users.groups.games = { };

  users.users."${currentSystemUser}".extraGroups = [ "games" ];
  services.desktopManager.plasma6.enable = true;

  jovian = {
    hardware.has.amd.gpu = hasAmdGPU;
    hardware.amd.gpu.enableBacklightControl = false;
    steam = {
      autoStart = true;
      enable = true;
      user = "steam-machine";
      desktopSession = "plasma";
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = compatPaths;
      };
    };
    steamos = {
      useSteamOSConfig = false;
      enableBluetoothConfig = true;
      enableDefaultCmdlineConfig = true;
      enableProductSerialAccess = true;
      enableSysctlConfig = true;
    };
  };

  programs.steam.localNetworkGameTransfers.openFirewall = true;
  # Add sunshine game streaming
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      origin_web_ui_allowed = "pc";
    };
  };

  programs.alvr.enable = true;
  programs.alvr.openFirewall = true;
  # doesn't build with 6.15 kernel currently, and not in use
  # hardware.xone.enable = true;

}
