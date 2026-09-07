/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  # this is how one would e.g. overlay the `microsoft-identity-broker` package with new package definition in ../pkgs/microsoft-identity-broker.nix
  # microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
  # https://github.com/NixOS/nixpkgs/issues/507531
  direnv = prev.direnv.overrideAttrs (_: {
    doCheck = false;
  });
}
