{
  pkgs,
  lib,
  currentSystemUser,
  ...
}:
let
  # Use the packaged Omarchy tree to source the TTF
  omarchyPkg = import ./omarchy-pkg.nix { inherit pkgs; };
  omarchyFont = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-font";
    version = "2.0.0";
    dontUnpack = true;
    installPhase = ''
      install -Dm444 "${omarchyPkg}/config/omarchy.ttf" "$out/share/fonts/truetype/omarchy/omarchy.ttf"
    '';
    meta = {
      description = "Omarchy logo font for Waybar";
      platforms = pkgs.lib.platforms.all;
    };
  };
in
{
  home-manager.users.${currentSystemUser} = {
    imports = [ ./home-manager.nix ];
  };
  hardware.bluetooth.enable = true;
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

  # Fonts used by Omarchy configs (Waybar/Alacritty/Hyprlock/Walker)
  fonts = {
    fontconfig.enable = true;
    packages = [
      omarchyFont
    ]
    ++ (with pkgs.nerd-fonts; [
      # Full Nerd Fonts set to guarantee presence of CaskaydiaMono family
      # Later we can slim this with: nerdfonts.override { fonts = [ "CaskaydiaCove" ]; }
      caskaydia-cove
      caskaydia-mono
    ]);
  };

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
  };
  # disabled fprintAuth from greetd to unlock gnome-keyring on first login
  security.pam.services.greetd.fprintAuth = false;
  # Ensure DBus broker when running Hyprland
  services.dbus.implementation = lib.mkForce "broker";
  environment.systemPackages = with pkgs; [
    nautilus
    brightnessctl
    playerctl
    walker
    mako
    waybar
    imv
    fcitx5
    fcitx5-gtk
    kdePackages.fcitx5-qt
    # Qt Kvantum style plugin (Qt5 + Qt6)
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    swaybg
    swayosd
    wiremix
    pamixer
    blueberry
    alacritty
    wl-clip-persist
    slurp
    satty
    wl-screenrec
    hyprshot
    terminaltexteffects
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
            # disable OnlyShowIn to allow xdg-autostart in any DE
            for f in "$out"/etc/xdg/autostart/*.desktop; do
              [ -e "$f" ] || continue
              substituteInPlace "$f" \
                --replace-fail "OnlyShowIn=" "#OnlyShowIn="
            done
          '';
      });
    })
  ];
}
