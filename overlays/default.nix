/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  # intune-portal = final.callPackage ../pkgs/intune-portal.nix { };
  microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
  # use version 4.0.0 for darwin support
  nh = final.callPackage ../pkgs/nh.nix { };
}
