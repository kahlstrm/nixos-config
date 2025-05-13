{
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  email,
  wsl ? false,
  stable ? false,
}:

let
  # True if this is a WSL system.
  isWSL = wsl;
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
    home-manager
    ;
  # The config files for this system.
  nixConfig = ../modules/nix-config/default.nix;
  machineConfig = ../machines/${name}.nix;
  OSConfig = ../modules/${if isDarwin then "darwin" else "nixos"}.nix;
  HMConfig = ../modules/home-manager.nix;
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
  specialArgs = {
    inherit isWSL isDarwin isLinux inputs;
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
    currentSystemEmail = email;
  };
in
assert isWSL -> !isDarwin;
systemFunc {
  inherit system specialArgs;
  # We expose some extra arguments so that our modules can parameterize
  # better based on these values.
  modules = [
    # Apply our overlays. Overlays are keyed by system type so we have
    # to go through and apply our system type. We do this first so
    # the overlays are available globally.
    { nixpkgs.overlays = overlays; }

    # Allow unfree packages.
    { nixpkgs.config.allowUnfree = true; }

    # Bring in WSL if this is a WSL build
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else { })
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
  ];
}
