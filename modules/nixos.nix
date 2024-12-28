{ pkgs, currentSystemUser, ... }:

{
  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

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
