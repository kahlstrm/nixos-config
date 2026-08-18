{
  config,
  lib,
  ...
}:
let
  cfg = config.local.remoteBuilder;
in
{
  options.local.remoteBuilder = {
    enable = lib.mkEnableOption "the restricted Nix remote builder endpoint";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys authorized to submit remote builds.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.sshServe = {
      enable = true;
      protocol = "ssh-ng";
      write = true;
      trusted = true;
      keys = cfg.authorizedKeys;
    };
  };
}
