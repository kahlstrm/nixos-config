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

  # packages to install to all systems:
  # TODO: make an assert check that verifies that these packages are available on all target platforms
  allSystemsPackages = with pkgs; [
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
    go
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
    gh
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
    lsof
    openssl
  ];

  darwinOnlyPackages = with pkgs; [
    dockutil
    cocoapods
    # manage python/node/jvm stuff outside of nix for the moment on darwin
    pkgs-unstable.mise
  ];

  # TODO: make an assertion that checks package availability for both x86_64 and aarch64
  linuxOnlyPackages = with pkgs; [
    openssh
    gcc
    clang
    awscli2
    parted
    lm_sensors
  ];

  # TODO: make an assertion that checks package availability for both x86_64 and aarch64
  linuxGUIPackages = with pkgs; [
    brave
    bitwarden-desktop
    valgrind
    xclip
    wl-clipboard
    ghostty
  ];

  linuxAmd64Packages = with pkgs; [
    linuxPackages.turbostat
  ];

  linuxAmd64GUIPackages = with pkgs; [
    spotify
    slack
  ];

in
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # If you have nh installed:
  # $ nh search wget
  environment.systemPackages =
    allSystemsPackages
    ++ lib.optionals isDarwin darwinOnlyPackages
    ++ lib.optionals isLinux linuxOnlyPackages
    ++ lib.optionals (currentSystem == "x86_64-linux") linuxAmd64Packages
    ++ lib.optionals (isLinux && guiEnabled) linuxGUIPackages
    ++ lib.optionals (currentSystem == "x86_64-linux" && guiEnabled) linuxAmd64GUIPackages;

  # workaround to allow global npm package installs
  environment.etc.npmrc.text = ''
    prefix = ''${HOME}/.npm
  '';
  environment.variables.NPM_CONFIG_GLOBALCONFIG = "/etc/npmrc";

  environment.variables.EDITOR = "vim";
}
