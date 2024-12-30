{
  pkgs,
  currentSystemUser,
  currentSystemName,
  ...
}:

{
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

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

  nixpkgs.overlays = import ../lib/overlays.nix;
}
