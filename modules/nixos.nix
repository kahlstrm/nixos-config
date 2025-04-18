{
  pkgs,
  currentSystemUser,
  currentSystemName,
  ...
}:

{
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;
  nixpkgs.overlays = import ../lib/overlays.nix;

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

  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [
        "com.mitchellh.ghostty.desktop"
      ];
    };
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  # Virtualization settings
  virtualisation.docker.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

}
