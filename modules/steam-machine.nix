{ pkgs, ... }:
{
  users.groups."steam-machine" = { };
  users.users."steam-machine" = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "video"
      "input"
    ];
    group = "steam-machine";
  };

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
        "--adaptive-sync" # VRR support
        "--hdr-enabled"
        "--hdr-itm-enabled"
        "--mangoapp" # performance overlay
        "--rt"
        "--xwayland-count 2"
        "-f"
        "-r 120"
      ];
      env = {
        # MANGOHUD = "1";
        ENABLE_GAMESCOPE_WSI = "1";
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
