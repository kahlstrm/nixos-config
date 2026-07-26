{ port, slicerPort }:
{ lib, pkgs, ... }:

let
  dataDir = "/var/lib/bambuddy";
  bambuddyVersion = pkgs.bambuddy.version;
  slicerImageDigests = {
    "0.2.4.8" = "sha256:1a694a3d834619b463db195881c03c920193e1c9882bc79139785ea0b03746b7";
  };
  slicerImageDigest =
    slicerImageDigests.${bambuddyVersion}
      or (throw "No Bambu Studio API sidecar digest for Bambuddy ${bambuddyVersion}");
in
{
  systemd.services.bambuddy = {
    description = "Bambuddy Bambu Lab printer manager";
    documentation = [ "https://wiki.bambuddy.cool/" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    environment = {
      BAMBU_STUDIO_API_URL = "http://127.0.0.1:${toString slicerPort}";
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

  virtualisation.oci-containers = {
    backend = "docker";

    containers.bambu-studio-api = {
      image = "ghcr.io/maziggy/bambu-studio-api:bambuddy-${bambuddyVersion}@${slicerImageDigest}";
      ports = [ "127.0.0.1:${toString slicerPort}:3000" ];
      volumes = [ "bambu-studio-api:/app/data" ];
      environment = {
        NODE_ENV = "production";
        PORT = "3000";
      };
      extraOptions = [
        "--health-cmd=curl --fail http://127.0.0.1:3000/health"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-start-period=10s"
        "--health-retries=3"
      ];
    };
  };
}
