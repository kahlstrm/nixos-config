{ currentSystemUser, pkgs, ... }:
{
  nix = {
    settings = {
      allowed-users = [ "${currentSystemUser}" ];
      trusted-users = [
        "@admin"
        "${currentSystemUser}"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    package = pkgs.nix;
  };
}
