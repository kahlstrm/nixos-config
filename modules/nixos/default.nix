{
  pkgs,
  currentSystemUser,
  currentSystemName,
  isLinux,
  guiEnabled,
  lib,
  ...
}:

{
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;
  programs.firefox.enable = isLinux && guiEnabled;
  programs.npm.enable = true;

  networking.hostName = currentSystemName;

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    home = "/home/${currentSystemUser}";
    extraGroups = [
      "docker"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Enables native Wayland on Chromium/Electron based applications
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.terminal-exec = lib.optionalAttrs guiEnabled {
    enable = true;
    settings = {
      default = [
        "com.mitchellh.ghostty.desktop"
      ];
    };
  };

  programs.zsh.enable = true;
  programs.vim = {
    enable = true;
    defaultEditor = false;
  };
  environment.etc."vimrc.local".text = ''
    set number
    set relativenumber
  '';
  programs.nix-ld.enable = true;
  # Virtualization settings
  virtualisation.docker.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
}
