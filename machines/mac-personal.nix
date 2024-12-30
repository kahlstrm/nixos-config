{
  pkgs,
  currentSystemUser,
  ...
}:
{
  system.stateVersion = 5;

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;

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
    ];
    masApps = {
      "tailscale" = 1475387142;
      "telegram" = 747648890;
      "slack" = 803453959;
    };
    taps = [ "mongodb/brew" ];
    # doesn't seem to exist in nixpkgs
    brews = [ "mongodb-database-tools" ];
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];
  home-manager.users.${currentSystemUser}.home.packages = with pkgs; [
    atlas
    turso-cli
  ];
}
