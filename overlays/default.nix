/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  lact = final.callPackage ../pkgs/lact.nix { };
  # this is how one would e.g. overlay the `microsoft-identity-broker` package with new package definition in ../pkgs/microsoft-identity-broker.nix
  # microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
}
