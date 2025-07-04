{
  currentSystemUser,
  pkgs,
  os-short,
  currentSystemName,
  lib,
  ...
}:
let
  isNotPannu = currentSystemName != "pannu";
in
{
  imports = [
    ./${os-short}.nix
  ];
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    settings = {
      allowed-users = [ "${currentSystemUser}" ];
      trusted-users = [
        "${currentSystemUser}"
      ];

      substituters = [
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      builders-use-substitutes = true;
    };
    package = pkgs.nix;
  };
}
