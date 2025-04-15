{
  lib,
  pkgs,
  isWSL,
  inputs,
  currentSystem,
  pkgs-unstable,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
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
      coreutils
      inetutils
      dig
      iftop
      killall
      btop
      htop
      neofetch
      mariadb
      sqlite
      postgresql
      wget
      rclone

      # Encryption and security tools
      age
      #age-plugin-yubikey
      gnupg
      libfido2

      # Cloud-related tools and SDKs
      # awscli2
      rustup
      pkgs-unstable.go
      terraform
      dive
      nodejs
      python3
      uv
      deno
      bun
      nixfmt-rfc-style
      protobuf
      # manage python/node/jvm stuff outside of nix for the moment
      pkgs-unstable.mise

      # Media-related packages
      ffmpeg

      # Source code management, Git, GitHub tools
      git
      pkgs-unstable.gh
      git-filter-repo

      # Text and terminal utilities
      pkgs-unstable.neovim
      delta
      bat
      jq
      yq-go
      fd
      fzf
      ripgrep
      tree
      tmux
      unrar
      unzip
      zip
      hyperfine
      wrk
      tlrc
      cmake
      gnumake
      parallel
      file
      openssl
    ]
    ++ (lib.optionals isDarwin [
      dockutil
      cocoapods
    ])
    ++ (lib.optionals isLinux) [
      # For Keychain support we use Apple's patched version on MacOS
      # https://github.com/NixOS/nixpkgs/issues/62353
      openssh
      gcc
      clang
      awscli2
    ]
    ++ (lib.optionals (isLinux && !isWSL) [
      firefox
      valgrind
      xclip
      wl-clipboard
      # Ghostty is installed via Cask on Mac
      inputs.ghostty.packages.${currentSystem}.default
    ]);
}
