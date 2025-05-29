{ pkgs, currentSystemUser, ... }:
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

  # doesn't build with 6.15 kernel currently, and not in use
  # hardware.xone.enable = true;

  services.getty.autologinUser = "steam-machine";
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "steam-machine";
      command = "steam-gamescope > /dev/null 2>&1";
    };
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession = {
      enable = true;
      args = [
        "--hdr-enabled"
        "--hdr-itm-enabled"
        "--mangoapp" # performance overlay
        "--xwayland-count 2"
        "--rt"
        "-f"
        "-H 2160"
        "-r 120"
      ];
      env = {
        ENABLE_GAMESCOPE_WSI = "1";
        ENABLE_HDR_WSI = "1";
        DXVK_HDR = "1";
        # MANGOHUD = "1";
      };
      steamArgs = [
        "-pipewire-dmabuf"
        "-gamepadui"
        "-steamos3"
        "-steampal"
        "-steamdeck"
      ];
    };
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
    extraPackages = with pkgs; [
      mangohud
      gamescope-wsi
    ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      MultiProfile = "multiple";
      FastConnectable = true;
    };
  };
}
