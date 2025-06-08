/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
}
