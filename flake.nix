{
  description = "Nix/NixOS system configurations";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable-nixos.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Build a custom WSL installer
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager-stable-nixos = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-nixos";
    };

    home-manager-stable-darwin = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-darwin";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    darwin-unstable = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    darwin-stable = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-darwin";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
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
          inputs
          ;
      };
    in
    {
      darwinConfigurations.mac-personal = mkSystem "mac-personal" {
        system = "aarch64-darwin";
        user = "kalski";
        email = personalEmail;
      };

      darwinConfigurations.mac-work = mkSystem "mac-work" {
        system = "aarch64-darwin";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
      };

      nixosConfigurations.frame-work = mkSystem "frame-work" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
      };

      nixosConfigurations.vm-amd = mkSystem "vm-amd" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
      };

      nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
        system = "aarch64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
      };

      nixosConfigurations.wsl = mkSystem "wsl" {
        system = "x86_64-linux";
        user = "kahlstrm";
        # TODO: should wsl-builds have parameterized email?
        email = personalEmail;
        wsl = true;
      };

    };
}
