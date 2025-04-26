{
  ...
}:
{
  imports = [
    ./vm-shared.nix
    ./hardware/vm-amd.nix
  ];
  hardware.graphics.enable = true;
  system.stateVersion = "24.11"; # Did you read the comment?
}
