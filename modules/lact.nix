{
  hasAmdGPU ? false,
  adminUser ? null,
}:
{ lib, pkgs, ... }:
let
  lact = pkgs.lact.override {
    libdisplay-info = pkgs.libdisplay-info_0_2;
  };
in
{
  hardware.amdgpu.overdrive.enable = hasAmdGPU;

  environment = {
    systemPackages = [ lact ];
    etc = lib.mkIf (adminUser != null) {
      "lact/config.yaml" = {
        text = ''
          daemon:
            log_level: info
            admin_user: ${adminUser}
        '';
        mode = "0644";
      };
    };
  };
  systemd = {
    packages = [ lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };
}
