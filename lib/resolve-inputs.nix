{
  stable,
  inputs,
  system,
}:
let
  isDarwin = (import inputs.nixpkgs-unstable { inherit system; }).stdenv.isDarwin;
  isLinux = (import inputs.nixpkgs-unstable { inherit system; }).stdenv.isLinux;
  darwin = if stable then inputs.darwin-stable else inputs.darwin-unstable;
  stable-suffix = if isDarwin then "stable-darwin" else "stable-nixos";
  nixpkgs-stable = inputs."nixpkgs-${stable-suffix}";
  nixpkgs = if stable then nixpkgs-stable else inputs.nixpkgs-unstable;
  home-manager =
    if stable then inputs."home-manager-${stable-suffix}" else inputs.home-manager-unstable;
in
{
  inherit isDarwin isLinux nixpkgs-stable;
  systemFunc = if isDarwin then darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if isDarwin then home-manager.darwinModules else home-manager.nixosModules;
  inherit (import nixpkgs { inherit system; }) lib;
}
