{
  ...
}:
{
  # Set in Sept 2024 as part of the macOS Sequoia release.
  system.stateVersion = 5;

  # Allow Sudo with Touch ID. TODO: move back to darwin.nix when stable encounters same issue
  security.pam.services.sudo_local.touchIdAuth = true;

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
    ];
    masApps = {
      "telegram" = 747648890;
    };
  };

}
