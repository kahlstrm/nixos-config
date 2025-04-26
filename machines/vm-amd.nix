{
  ...
}:
{
  imports = [
    ./vm-shared.nix
    ./hardware/vm-amd.nix
  ];
  system.stateVersion = "24.11"; # Did you read the comment?
}
