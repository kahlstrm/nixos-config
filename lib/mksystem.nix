{
  inputOverlays,
  inputs,
  flakeRootPath,
}:

name:
{
  system,
  user,
  email,
  gui ? true,
  useOutOfStoreSymlink ? true,
  wsl ? false,
  stable ? false,
  allowUnfree ? true,
  # https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
  secureBoot ? false,
}:

let
  overlays = inputOverlays ++ import ./overlays.nix;
  # resolves NixOS vs nix-darwin and stable vs unstable functions
  inherit
    (import ./resolve-inputs.nix {
      inherit
        system
        stable
        inputs
        ;
    })
    isDarwin
    isLinux
    lib
    systemFunc
    nixpkgs-stable
    nixpkgs-unstable
    nix-index-database
    os-short
    home-manager
    lanzaboote
    ;
  # The config files for this system.
  nixConfig = ../modules/nix-config;
  machineConfig = ../machines/${name}.nix;
  OSConfig = ../modules/${os-short};
  HMConfig = ../modules/home-manager;
  systemPackages = ../modules/packages.nix;
  # TODO: make this cleaner
  nix-homebrew = lib.optionalAttrs isDarwin inputs.nix-homebrew.darwinModules.nix-homebrew;
  nix-homebrew-config = lib.optionalAttrs isDarwin {
    nix-homebrew = {
      enable = true;
      inherit user;
      # Detect and automatically migrate existing Homebrew installations
      autoMigrate = true;
      # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
      #mutableTaps = false;
    };
  };
  guiEnabled = (!wsl && gui) || isDarwin;
  specialArgs = {
    inherit
      guiEnabled
      isDarwin
      isLinux
      os-short
      nix-index-database
      useOutOfStoreSymlink
      ;
    pkgs-stable = import nixpkgs-stable {
      inherit system overlays;
      config.allowUnfree = allowUnfree;
    };
    pkgs-unstable = import nixpkgs-unstable {
      inherit system overlays;
      config.allowUnfree = allowUnfree;
    };
    nixos-hardware = inputs.nixos-hardware;
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
    currentSystemEmail = email;
    flakeRoot = flakeRootPath;
    isStable = stable;
  };
in
assert wsl -> !isDarwin;
systemFunc {
  inherit system specialArgs;
  # We expose some extra arguments so that our modules can parameterize
  # better based on these values.
  modules =
    [
      {
        # Apply our overlays. Overlays are keyed by system type so we have
        # to go through and apply our system type. We do this first so
        # the overlays are available globally.
        nixpkgs.overlays = overlays;

        # Allow unfree packages.
        nixpkgs.config.allowUnfree = allowUnfree;
      }

      nixConfig
      nix-homebrew
      nix-homebrew-config
      systemPackages
      OSConfig
      # TODO: make user config & home-manager optional
      home-manager.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = import HMConfig;
        home-manager.extraSpecialArgs = specialArgs;
      }
      machineConfig
    ]
    # Bring in WSL if this is a WSL build
    ++ (lib.optionals wsl [
      inputs.nixos-wsl.nixosModules.wsl
    ])
    ++ (lib.optionals secureBoot [
      lanzaboote.nixosModules.lanzaboote
      ../modules/lanzaboote.nix
    ]);
}
