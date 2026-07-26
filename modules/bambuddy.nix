{ port }:
{ lib, pkgs, ... }:

let
  dataDir = "/var/lib/bambuddy";
in
{
  systemd.services.bambuddy = {
    description = "Bambuddy Bambu Lab printer manager";
    documentation = [ "https://wiki.bambuddy.cool/" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    environment = {
      DATA_DIR = dataDir;
      LOG_DIR = "${dataDir}/logs";
    };

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.bambuddy} --host 127.0.0.1 --port ${toString port}";
      Restart = "on-failure";
      RestartSec = "5s";

      DynamicUser = true;
      StateDirectory = "bambuddy";
      StateDirectoryMode = "0700";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
