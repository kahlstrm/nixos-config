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
  wrapNixLDIfLinux =
    pkg: binName:
    if isLinux then
      (pkgs.writeShellScriptBin binName ''
        export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
        exec ${pkg}/bin/${binName} "$@"
      '')
    else
      pkg;

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
    wireguard-tools

    # Encryption and security tools
    # age
    # age-plugin-yubikey
    # libfido2
    gnupg

    # Cloud-related tools and SDKs
    # awscli2
    clang
    gcc
    ssm-session-manager-plugin
    rustup
    go
    terraform
    nodejs
    corepack
    python3
    (wrapNixLDIfLinux bun "bun")
    jdk

    uv
    nixfmt-rfc-style
    protobuf
    kubectl
    talosctl
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

  AllSystemGUIPackages = with pkgs; [
    vscode
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
    awscli2
    google-cloud-sdk
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
    ++ lib.optionals guiEnabled AllSystemGUIPackages
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
