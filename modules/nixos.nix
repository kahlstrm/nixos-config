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

  # Virtualization settings
  virtualisation.docker.enable = true;

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

}
