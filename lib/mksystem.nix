{
  nixpkgs,
  nixpkgs-stable,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  email,
  wsl ? false,
}:

let
  # True if this is a WSL system.
  isWSL = wsl;
  isDarwin = (import nixpkgs { inherit system; }).stdenv.isDarwin;
  # The config files for this system.
  nixConfig = ../modules/nix-config-base.nix;
  machineConfig = ../machines/${name}.nix;
  OSConfig = ../modules/${if isDarwin then "darwin" else "nixos"}.nix;
  HMConfig = ../modules/home-manager.nix;
  systemPackages = ../modules/packages.nix;
  # NixOS vs nix-darwin functions
  systemFunc = if isDarwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  # TODO: make this cleaner
  nix-homebrew = if isDarwin then inputs.nix-homebrew.darwinModules.nix-homebrew else { };
  nix-homebrew-config =
    if isDarwin then
      {
        nix-homebrew = {
          enable = true;
          inherit user;
          # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
          #mutableTaps = false;
        };
      }
    else
      { };
  specialArgs = {
    pkgs-stable = import nixpkgs-stable {
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
    nix-homebrew
    nix-homebrew-config
    systemPackages
    machineConfig
    # TODO: make user OS Config & home-manager optional
    OSConfig
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import HMConfig specialArgs;
    }
  ];
}
