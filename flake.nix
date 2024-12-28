{
  description = "Nix/NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Build a custom WSL installer
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      ...
    }@inputs:
    let
      # Overlays is the list of overlays we want to apply from flake inputs.
      overlays = [
      ];
      personalEmail = "kalle.ahlstrom@iki.fi";
      workEmail = "kalle.ahlstrom@nitor.com";

      mkSystem = import ./lib/mksystem.nix {
        inherit
          overlays
          nixpkgs
          inputs
          nixpkgs-stable
          ;
      };
    in
    {
      darwinConfigurations.mac-personal = mkSystem "mac-personal" {
        system = "aarch64-darwin";
        user = "kalski";
        email = personalEmail;
      };
      # nixosConfigurations.nixos-personal = mkSystem "nixos-personal" rec {
      #   system = "x86_64-linux";
      #   user = "kahlstrm";
      #   email = personalEmail;
      # };

      nixosConfigurations.wsl = mkSystem "wsl" {
        system = "x86_64-linux";
        user = "kahlstrm";
        # TODO: should wsl-builds have parameterized email?
        email = personalEmail;
        wsl = true;
      };

    };
}
