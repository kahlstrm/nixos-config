/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {

  # Fix 1password not working properly on Linux arm64.
  #_1password = final.callPackage ../pkgs/1password.nix {};
}
