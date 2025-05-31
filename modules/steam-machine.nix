{ currentSystemUser, pkgs, ... }:
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
    steam = {
      autoStart = true;
      enable = true;
      user = "steam-machine";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = false;
      enableBluetoothConfig = true;
      enableDefaultCmdlineConfig = true;
      enableMesaPatches = true;
      enableProductSerialAccess = true;
      enableSysctlConfig = true;
    };
  };

  programs.steam.remotePlay.openFirewall = true;
  programs.steam.localNetworkGameTransfers.openFirewall = true;

  # Steam seems to ping this one also
  networking.firewall.allowedTCPPorts = [ 27037 ];

  # doesn't build with 6.15 kernel currently, and not in use
  # hardware.xone.enable = true;

}
