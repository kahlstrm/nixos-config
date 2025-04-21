{
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.dash-to-dock
  ];
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
                "slack.desktop"
                "bitwarden.desktop"
                "org.gnome.Settings.desktop"
                "firefox.desktop"
              ];
              enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" ];
            };
            "org/gnome/shell/extensions/dash-to-dock" = {
              apply-custom-theme = true;
              custom-theme-shrink = true;
              disable-overview-on-startup = false;
              dock-position = "BOTTOM";
              intellihide-mode = "ALL_WINDOWS";
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
                "<Control><Super>space"
              ];
              switch-input-source-backward = [
                "<Shift><Control><Super>space"
              ];

            };
          };
        }
      ];
    };

  };
}
