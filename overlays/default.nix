/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  # use version 4.0.0 for darwin support
  nh = final.callPackage ../pkgs/nh.nix { };
}
