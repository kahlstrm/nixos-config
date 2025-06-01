{
  ...
}:
{
  imports = [
    ./vm-shared.nix
    ./hardware/vm-utm.nix
    ../modules/gnome.nix
    ../modules/keyd.nix
  ];
  # Install firefox.
  programs.firefox.enable = true;
  hardware.graphics.enable = true;
  system.stateVersion = "24.11"; # Did you read the comment?
}
