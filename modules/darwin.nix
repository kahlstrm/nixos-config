{
  pkgs,
  currentSystemUser,
  ...
}:

# https://daiderd.com/nix-darwin/manual/index.html
{
  imports = [ ./darwin-dock.nix ];
  nixpkgs.overlays = import ../lib/overlays.nix;

  homebrew = {
    enable = true;
    # TODO: enable rest when have the time to migrate
    casks = [
      # Development Tools
      # "visual-studio-code"
      "orbstack"
      "ghostty" # automatic update support on MacOS, hence separate

      # Communication Tools
      "chatgpt"

      # Utility Tools
      "shottr"
      "linearmouse"
    ];
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    taps = [ ];
    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    masApps = {
      "bitwarden" = 1352778147;
    };
  };
  nix.gc = {
    user = "root";
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
  # MacOS specific packages that are to be installed systemwide
  environment.systemPackages = with pkgs; [ dockutil ];

  # Allow Sudo with Touch ID.
  security.pam.enableSudoTouchIdAuth = true;

  # some of these are documented at https://macos-defaults.com/
  # https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.CustomSystemPreferences
  # Some are defined explicitly, while other need to use either
  # CustomSystemPreferences or CustomUserPreferences
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;

      KeyRepeat = 2; # Values: 120, 90, 60, 30, 12, 6, 2
      InitialKeyRepeat = 25; # Values: 120, 94, 68, 35, 25, 15

      # "com.apple.mouse.tapBehavior" = 1;
      # "com.apple.sound.beep.volume" = 0.0;
      # "com.apple.sound.beep.feedback" = 0;
    };
    menuExtraClock = {
      Show24Hour = true;
      ShowDayOfWeek = true;
      ShowDate = 0;
      ShowSeconds = true;
    };
    dock = {
      autohide = true;
      show-recents = true;
      launchanim = true;
      orientation = "bottom";
    };

    finder = {
      _FXShowPosixPathInTitle = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock.enable = true;
  local.dock.entries = [
    # installed from brew/App Store
    { path = "/Applications/Ghostty.app/"; }
    { path = "/Applications/Brave Browser.app/"; }
    { path = "/Applications/Slack.app/"; }
    { path = "/System/Applications/System Settings.app"; }
    { path = "/Applications/Bitwarden.app"; }
    {
      path = "/Users/${currentSystemUser}/Downloads/";
      section = "others";
    }
  ];

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.${currentSystemUser} = {
    home = "/Users/${currentSystemUser}";
    shell = pkgs.zsh;
  };
}
