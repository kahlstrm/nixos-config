{
  description = "Nix/NixOS system configurations";

  inputs = {
    nixpkgs-unstable-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable-nixos.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable-nixos.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-stable-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";

    mdatp = {
      url = "github:NitorCreations/nix-mdatp";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

    home-manager-unstable-darwin = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable-darwin";
    };

    home-manager-unstable-nixos = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

    home-manager-stable-nixos = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-nixos";
    };

    home-manager-stable-darwin = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-darwin";
    };

    nix-index-database-darwin = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable-darwin";
    };

    nix-index-database-nixos = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

    darwin-unstable = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable-darwin";
    };

    darwin-stable = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable-darwin";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Secure boot, instructions https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
    lanzaboote-unstable = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

    lanzaboote-stable = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs-stable-nixos";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Build a custom WSL installer
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

    nixarr-stable = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs-stable-nixos";
    };

    nixarr-unstable = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs-unstable-nixos";
    };

  };

  outputs =
    {
      ...
    }@inputs:
    let
      # Overlays is the list of overlays we want to apply from flake inputs.
      inputOverlays = [
      ];
      personalEmail = "kalle.ahlstrom@iki.fi";
      workEmail = "kalle.ahlstrom@nitor.com";

      mkSystem = import ./lib/mksystem.nix {
        inherit
          inputOverlays
          inputs
          ;
        flakeRootPath = ./.;
        personalEmail = personalEmail;
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

      nixosConfigurations.pannu = mkSystem "pannu" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = personalEmail;
        stable = false;
        gui = false;
        useOutOfStoreSymlink = false;
      };

      nixosConfigurations.poenttoe = mkSystem "poenttoe" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = personalEmail;
        stable = true;
        gui = false;
        useOutOfStoreSymlink = false;
        packages = {
          dev = false;
          cloud = false;
          databases = false;
        };
      };

      nixosConfigurations.zima = mkSystem "zima" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = personalEmail;
        stable = true;
        gui = false;
        useOutOfStoreSymlink = false;
        packages = {
          dev = false;
          cloud = false;
          databases = false;
        };
      };

      nixosConfigurations.frame-work = mkSystem "frame-work" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
        secureBoot = true;
      };

      nixosConfigurations.vm-amd = mkSystem "vm-amd" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
        useOutOfStoreSymlink = false;
      };

      nixosConfigurations.vm-utm-aarch64 = mkSystem "vm-utm-aarch64" {
        system = "aarch64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
        useOutOfStoreSymlink = false;
      };

      nixosConfigurations.vm-utm-x86_64 = mkSystem "vm-utm-x86_64" {
        system = "x86_64-linux";
        user = "kahlstrm";
        email = workEmail;
        stable = false;
        useOutOfStoreSymlink = false;
      };

      nixosConfigurations.wsl = mkSystem "wsl" {
        system = "x86_64-linux";
        user = "kahlstrm";
        # TODO: should wsl-builds have parameterized email?
        email = personalEmail;
        wsl = true;
        useOutOfStoreSymlink = false;
      };

    };
}
