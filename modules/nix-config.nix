{
  currentSystemUser,
  isDarwin,
  lib,
  pkgs,
  ...
}:
{
  nix = {
    gc = lib.mkMerge [
      {
        automatic = true;
        options = "--delete-older-than 30d";
      }

      (lib.mkIf isDarwin {
        interval = {
          Weekday = 0; # Sunday
          Hour = 0;
          Minute = 0;
        };
      })

      (lib.mkIf (!isDarwin) {
        dates = "weekly";
      })
    ];
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
