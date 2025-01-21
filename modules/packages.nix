{
  lib,
  pkgs,
  isWSL,
  inputs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
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
      go
      terraform
      dive
      nodejs
      python3
      uv
      deno
      bun
      nixfmt-rfc-style
      # manage python/node/jvm stuff outside of nix for the moment
      mise

      # Media-related packages
      ffmpeg

      # Source code management, Git, GitHub tools
      git
      gh
      git-filter-repo

      # Text and terminal utilities
      neovim
      delta
      bat
      jq
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
    ]
    ++ (lib.optionals (isLinux && !isWSL) [
      firefox
      valgrind
      xclip
      # Ghostty is installed via Cask on Mac
      inputs.ghostty.packages.${currentSystem}.default
    ]);
}
