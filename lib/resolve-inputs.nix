{
  stable,
  inputs,
  system,
}:
let
  isDarwin = (import inputs.nixpkgs-unstable-darwin { inherit system; }).stdenv.isDarwin;
  isLinux = (import inputs.nixpkgs-unstable-nixos { inherit system; }).stdenv.isLinux;
  darwin = if stable then inputs.darwin-stable else inputs.darwin-unstable;
  os-short = if isDarwin then "darwin" else "nixos";
  nix-index-database = inputs."nix-index-database-${os-short}";
  nixpkgs-stable = inputs."nixpkgs-stable-${os-short}";
  nixpkgs-unstable = inputs."nixpkgs-unstable-${os-short}";
  nixpkgs = if stable then nixpkgs-stable else nixpkgs-unstable;
  lanzaboote = if stable then inputs.lanzaboote-stable else inputs.lanzaboote-unstable;
  home-manager =
    if stable then
      inputs."home-manager-stable-${os-short}"
    else
      inputs."home-manager-unstable-${os-short}";
in
{
  inherit
    isDarwin
    isLinux
    nixpkgs-stable
    nixpkgs-unstable
    nix-index-database
    os-short
    lanzaboote
    ;
  systemFunc = if isDarwin then darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if isDarwin then home-manager.darwinModules else home-manager.nixosModules;
  inherit (import nixpkgs { inherit system; }) lib;
}
