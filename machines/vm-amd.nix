{
  pkgs,
  ...
}:
{
  imports = [
    ./vm-shared.nix
    ./hardware/vm-amd.nix
    ../modules/gnome.nix
    ../modules/keyd.nix
  ];
  # Install firefox.
  programs.firefox.enable = true;
  # Enables native Wayland on Chromium/Electron based applications
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
  ];
  hardware.graphics.enable = true;
  system.stateVersion = "24.11"; # Did you read the comment?
}
