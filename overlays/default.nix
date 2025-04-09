/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  # intune-portal = final.callPackage ../pkgs/intune-portal.nix { };
  # required for microsoft-identity-broker
  openjfx11 = final.callPackage ../pkgs/openjfx11/default.nix {
    withWebKit = true;
  };
  microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
}
