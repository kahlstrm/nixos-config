{
  config,
  lib,
  pkgs,
  useOutOfStoreSymlink,
  flakeRoot,
  ...
}:
let
  package = import ./omarchy-pkg.nix { inherit pkgs; };
  initialTheme = "tokyo-night";
  nixosConfigLocation = "${config.home.homeDirectory}/nixos-config";
in
{

  # Put omarchy bin on PATH so Hypr/menus find scripts without modification.
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/omarchy/bin" ];

  # Link the immutable content from the package into the home directory.
  home.file = {
    ".local/share/omarchy".source = package;
    ".config/omarchy/themes".source = lib.mkForce (package + "/themes");
  };

  xdg.configFile."hypr".source =
    if useOutOfStoreSymlink then
      # Create a directory symlink to .config/hypr, allowing mutable editing of config
      config.lib.file.mkOutOfStoreSymlink "${nixosConfigLocation}/config/hypr"
    else
      (flakeRoot + /config/hypr);
  programs.btop.settings.colortheme = lib.mkForce "current";

  # Symlink Walker config.toml from the packaged omarchy tree into ~/.config/walker/config.toml
  # This keeps it immutable and always in sync with the omarchy version.
  xdg.configFile."walker/config.toml".source = lib.mkForce (package + "/config/walker/config.toml");
  xdg.configFile."uwsm/env".text = ''
    export OMARCHY_PATH=$HOME/.local/share/omarchy
    export PATH=$OMARCHY_PATH/bin/:$PATH
  '';
  # Input Method env for Wayland/Qt via fcitx5
  xdg.configFile."environment.d/fcitx.conf".source = lib.mkForce (
    package + "/config/environment.d/fcitx.conf"
  );
  # Provide default screensaver text so the TTE-based screensaver works
  xdg.configFile."omarchy/branding/screensaver.txt".source = package + "/logo.txt";
  xdg.configFile."waybar".source = lib.mkForce (package + "/config/waybar");
  xdg.configFile."swayosd".source = lib.mkForce (package + "/config/swayosd");
  # Keep mako config following the current Omarchy theme
  xdg.configFile."mako/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/omarchy/current/theme/mako.ini";

  # Minimal bootstrap to ensure first-run works without the installer.
  home.activation.omarchyBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    omdir="$HOME/.config/omarchy"
    curdir="$omdir/current"
    themedir="$omdir/themes"

    mkdir -p "$curdir"

    # Seed current/theme if missing
    if [ ! -e "$curdir/theme" ]; then
      if [ -n "${initialTheme}" ] && [ -e "$themedir/${initialTheme}" ]; then
        ln -snf "$themedir/${initialTheme}" "$curdir/theme"
      else
        # pick the first available theme
        first_theme=$(find "$themedir" -mindepth 1 -maxdepth 1 -type d -o -xtype l | sort | head -n1)
        if [ -n "$first_theme" ]; then
          ln -snf "$first_theme" "$curdir/theme"
        fi
      fi
    fi

    # Seed current/background if missing and a theme exists
    if [ ! -e "$curdir/background" ] && [ -L "$curdir/theme" ]; then
      # Find the first background image under the current theme
      bg=$(find "$(readlink -f "$curdir/theme")/backgrounds" -type f 2>/dev/null | sort | head -n1)
      if [ -n "$bg" ]; then
        ln -snf "$bg" "$curdir/background"
      fi
    fi
  '';
}
