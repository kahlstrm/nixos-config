{
  pkgs,
  currentSystemUser,
  ...
}:
{
  system.stateVersion = 5;

  # Allow Sudo with Touch ID. TODO: move back to darwin.nix when stable encounters
  security.pam.services.sudo_local.touchIdAuth = true;

  # extra homebrew config for this machine specifically
  homebrew = {
    # TODO: migrate all these apps to casks
    casks = [
      "vlc"
      #"discord"
      #"zoom"
      #"google-chrome"
      "firefox"
      #"brave"
      "utm"
    ];
    masApps = {
      "tailscale" = 1475387142;
      "telegram" = 747648890;
      "slack" = 803453959;
      "wireguard" = 1451685025;
    };
  };

  home-manager.users.${currentSystemUser}.home.packages = with pkgs; [
    atlas
    turso-cli
    mongodb-tools
    mongosh
    erlang
    gleam
    dart
  ];
}
