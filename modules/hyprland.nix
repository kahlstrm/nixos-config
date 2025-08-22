{
  pkgs,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.hyprlock.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita";
        icon-theme = "Flat-Remix-Red-Dark";
        font-name = "Noto Sans Medium 11";
        document-font-name = "Noto Sans Medium 11";
        monospace-font-name = "Noto Sans Mono Medium 11";
      };
    }
  ];

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  # Enables native Wayland on Chromium/Electron based applications
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember -g 'Do or do not, there is no try' --time";
        user = "greeter";
      };
    };
    useTextGreeter = true;
  };
  security.pam.services.greetd.fprintAuth = false;
  environment.systemPackages = with pkgs; [
    nautilus
  ];
  nixpkgs.overlays = [
    # overlay required for xdg-autostart to work https://wiki.archlinux.org/title/GNOME/Keyring#Using_gnome-keyring-daemon_outside_desktop_environments_(KDE,_GNOME,_XFCE,_...)
    (final: prev: {
      gnome-keyring = prev.gnome-keyring.overrideAttrs (old: {
        postFixup =
          # keep upstream wrapper logic (useWrappedDaemon)
          (prev.lib.optionalString (old.useWrappedDaemon or true) ''
            files=("$out"/etc/xdg/autostart/* "$out"/share/dbus-1/services/*)
            for file in "''${files[@]}"; do
              [ -e "$file" ] || continue
              substituteInPlace "$file" \
                --replace "$out/bin/gnome-keyring-daemon" "/run/wrappers/bin/gnome-keyring-daemon"
            done
          '')
          + ''
            # remove OnlyShowIn to allow autostart in any DE
            for f in "$out"/etc/xdg/autostart/*.desktop; do
              [ -e "$f" ] || continue
              sed -i '/^OnlyShowIn=/d' "$f"
            done
          '';
      });
    })
  ];
}
