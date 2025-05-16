{
  currentSystemUser,
  isDarwin,
  pkgs,
  ...
}:
let
  os-short = if isDarwin then "darwin" else "nixos";
in
{
  imports = [
    ./${os-short}.nix
  ];
  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    settings = {
      allowed-users = [ "${currentSystemUser}" ];
      trusted-users = [
        "root"
        "${currentSystemUser}"
      ];

      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    package = pkgs.nix;
  };
}
