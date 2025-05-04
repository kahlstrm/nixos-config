{
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.dash-to-dock
    gnomeExtensions.caffeine
  ];
  # https://discourse.nixos.org/t/howto-disable-most-gnome-default-applications-and-what-they-are/13505
  environment.gnome.excludePackages = with pkgs; [
    epiphany # use firefox/brave instead
    geary
    yelp
    gnome-maps
    gnome-tour
    gnome-contacts
    simple-scan
    file-roller
    gnome-console
    orca
  ];
  # setup windowing environment
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };
  services.xserver.excludePackages = [ pkgs.xterm ];
  programs.dconf = {
    enable = true;
    profiles = {
      # A "user" profile with a database
      user.databases = [
        {
          lockAll = true;
          settings = {
            "org/gnome/shell" = {
              favorite-apps = [
                "com.mitchellh.ghostty.desktop"
                "brave-browser.desktop"
                "firefox.desktop"
                "slack.desktop"
                "bitwarden.desktop"
              ];
              enabled-extensions = [
                "dash-to-dock@micxgx.gmail.com"
                "caffeine@patapon.info"
              ];
            };
            "org/gnome/shell/extensions/dash-to-dock" = {
              apply-custom-theme = true;
              multi-monitor = true;
              custom-theme-shrink = true;
              disable-overview-on-startup = true;
              hotkeys-show-dock = false;
              show-trash = false;
              dock-position = "BOTTOM";
              intellihide-mode = "ALL_WINDOWS";
            };
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };
            "org/gnome/desktop/wm/keybindings" = {
              cycle-group = [
                "<Alt>Escape"
              ];
              cycle-group-backward = [
                "<Alt><Shift>Escape"
              ];
              cycle-windows = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
              cycle-windows-backward = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
              switch-input-source = [
                "<Super>space"
              ];
              switch-input-source-backward = [
                "<Shift><Super>space"
              ];

            };
            "org/gnome/desktop/peripherals/mouse" = {
              accel-profile = "flat";
            };
          };
        }
      ];
    };

  };
}
