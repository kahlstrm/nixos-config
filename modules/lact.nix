{
  hasAmdGPU ? false,
  adminUser ? null,
}:
{ lib, pkgs, ... }:
{
  hardware.amdgpu.overdrive.enable = hasAmdGPU;

  environment = {
    systemPackages = [ pkgs.lact ];
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
    packages = [ pkgs.lact ];
    services.lactd.wantedBy = [ "multi-user.target" ];
  };
}
