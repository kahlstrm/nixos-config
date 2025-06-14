{
  lib,
  pkgs,
  guiEnabled,
  isDarwin,
  isLinux,
  currentSystem,
  pkgs-unstable,
  ...
}:

let
  bun =
    if isLinux then
      pkgs.bun.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs or [ ] ++ [ pkgs.makeWrapper ];
        postInstall =
          oldAttrs.postInstall or ""
          + ''
            wrapProgram $out/bin/bun \
              --set LD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib/:$LD_LIBRARY_PATH"
          '';
      })
    else
      pkgs.bun;
in
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # If you have nh installed:
  # $ nh search wget
  environment.systemPackages =
    with pkgs;
    [
      # General packages for development and system management
      nixos-rebuild-ng
      coreutils
      gnused
      inetutils
      dig
      iftop
      killall
      btop
      htop
      fastfetch
      mariadb
      sqlite
      postgresql
      wget
      rclone
      dust
      dive
      vim

      # Encryption and security tools
      age
      #age-plugin-yubikey
      gnupg
      libfido2

      # Cloud-related tools and SDKs
      # awscli2
      ssm-session-manager-plugin
      rustup
      pkgs-unstable.go
      terraform
      nodejs
      corepack
      python3
      bun
      jdk

      uv
      nixfmt-rfc-style
      protobuf
      kubectl
      k9s
      fluxcd
      kubernetes-helm
      ollama

      # Media-related packages
      ffmpeg

      # Source code management, Git, GitHub tools
      git
      pkgs-unstable.gh
      git-filter-repo

      # Text and terminal utilities
      pkgs-unstable.neovim
      bat
      jq
      yq-go
      fd
      fzf
      ripgrep
      tree
      tmux
      unzip
      zip
      hyperfine
      wrk
      tlrc
      cmake
      gnumake
      just
      parallel
      file
      openssl
    ]
    ++ (lib.optionals isDarwin [
      dockutil
      cocoapods
      # manage python/node/jvm stuff outside of nix for the moment on darwin
      pkgs-unstable.mise
    ])
    ++ (lib.optionals isLinux) [
      # For Keychain support we use Apple's patched version on MacOS
      # https://github.com/NixOS/nixpkgs/issues/62353
      openssh
      gcc
      clang
      awscli2
      parted
      lm_sensors
      linuxPackages.turbostat
    ]
    # TODO: move to desktop-packages.nix
    ++ lib.optionals guiEnabled [
      pkgs-unstable.rquickshare
    ]
    ++ (lib.optionals (isLinux && guiEnabled) (
      [
        brave
        bitwarden-desktop
        valgrind
        xclip
        wl-clipboard
        # Ghostty is installed via Cask on Mac
        pkgs-unstable.ghostty
      ]
      ++ lib.optionals (currentSystem == "x86_64-linux") [
        spotify
        slack
      ]
    ));

  # workaround to allow global npm package installs
  environment.etc.npmrc.text = ''
    prefix = ''${HOME}/.npm
  '';

  environment.variables.EDITOR = "vim";
  environment.variables.NPM_CONFIG_GLOBALCONFIG = "/etc/npmrc";
}
