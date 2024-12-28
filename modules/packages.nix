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
      deno
      bun
      nixd
      nixfmt-rfc-style
      # manage python/node/jvm stuff outside of nix for the moment
      mise
      uv

      # Media-related packages
      ffmpeg

      # Source code management, Git, GitHub tools
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
    ]
    ++ (lib.optionals isDarwin [
      cocoapods
    ])
    ++ (lib.optionals (isLinux && !isWSL) [
      firefox
      valgrind
      # use Apple's patched SSH for useKeychain support https://github.com/NixOS/nixpkgs/issues/62353
      openssh
      # Ghostty is installed via Cask on Mac
      inputs.ghostty.packages.${currentSystem}.default
    ]);
}
