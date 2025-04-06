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
    systemFunc
    nixpkgs-stable
    home-manager
    ;
  # The config files for this system.
  nixConfig = ../modules/nix-config.nix;
  machineConfig = ../machines/${name}.nix;
  OSConfig = ../modules/${if isDarwin then "darwin" else "nixos"}.nix;
  HMConfig = ../modules/home-manager.nix;
  systemPackages = ../modules/packages.nix;
  # TODO: make this cleaner
  specialArgs = {
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
    isWSL = isWSL;
    inputs = inputs;
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
    systemPackages
    machineConfig
    OSConfig
    # TODO: make user config & home-manager optional
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import HMConfig;
      home-manager.extraSpecialArgs = specialArgs;
    }
  ];
}
