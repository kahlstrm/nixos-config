{
  pkgs,
  currentSystemUser,
  currentSystemName,
  ...
}:

# https://daiderd.com/nix-darwin/manual/index.html
{
  imports = [ ./darwin-dock.nix ];
  nixpkgs.overlays = import ../lib/overlays.nix;

  networking.hostName = currentSystemName;

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
    # completions from nixpkgs not work for some reason
    brews = [
      "awscli"
      "mas"
    ];
    masApps = {
      "bitwarden" = 1352778147;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

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
    # NOTE: if the key has dots it needs to be quoted.
    CustomUserPreferences = {
      "com.apple.ActivityMonitor".UpdatePeriod = 2;
      # Custom App Shortcuts
      # https://support.apple.com/en-us/guide/mac-help/mchlp2271/mac
      NSGlobalDomain.NSUserKeyEquivalents = {
        Zoom = "@~z";
      };
      # https://apple.stackexchange.com/questions/91679/is-there-a-way-to-set-an-application-shortcut-in-the-keyboard-preference-pane-vi
      "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        "27" = {
          enabled = true;
          value = {
            parameters = [
              65535
              53
              1048576
            ];
            type = "standard";
          };
        };
        "60" = {
          enabled = false;
          value = {
            parameters = [
              32
              49
              262144
            ];
            type = "standard";
          };
        };
        "61" = {
          enabled = 1;
          value = {
            parameters = [
              32
              49
              786432
            ];
            type = "standard";
          };
        };
        "65" = {
          enabled = 0;
          value = {
            parameters = [
              65535
              49
              1572864
            ];
            type = "standard";
          };
        };
        "80" = {
          enabled = false;
          value = {
            parameters = [
              65535
              123
              8781824
            ];
            type = "standard";
          };
        };
        "164" = {
          enabled = 0;
          value = {
            parameters = [
              65535
              65535
              0
            ];
            type = "standard";
          };
        };
      };
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

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];
}
