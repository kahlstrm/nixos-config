{ nixosConfigLocation }:
{
  pkgs,
  ...
}:
{
  # nix cli helper https://github.com/viperML/nh
  programs.nh = {
    enable = true;
    # automatically sets up FLAKE environment variable
    flake = nixosConfigLocation;
    package = pkgs.nh;
  };
}
