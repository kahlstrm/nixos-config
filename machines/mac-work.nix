{
  ...
}:
{
  # Set in Sept 2024 as part of the macOS Sequoia release.
  system.stateVersion = 5;

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;

  # Allow Sudo with Touch ID. TODO: move back to darwin.nix when stable encounters same issue
  security.pam.enableSudoTouchIdAuth = true;

  # extra homebrew config for this machine specifically
  homebrew = {
    # TODO: migrate all these apps to casks
    casks = [
      "visual-studio-code"
      "postman"
      "session-manager-plugin"
      #"discord"
      #"zoom"
      #"google-chrome"
      #"firefox"
      #"brave"
    ];
    brews = [
      "swagger-codegen"
      "awscli"
    ];
    masApps = {
      "telegram" = 747648890;
    };
  };

}
