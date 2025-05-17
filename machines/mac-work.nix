{
  ...
}:
{
  # Set in Sept 2024 as part of the macOS Sequoia release.
  system.stateVersion = 5;

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
