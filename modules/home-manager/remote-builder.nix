{
  hostName,
  sshKey,
}:
{ lib, pkgs, ... }:
let
  builder = "ssh-ng://nix-ssh@${hostName} x86_64-linux,aarch64-linux ${sshKey} 4 1 big-parallel";

  mkPannuWrapper =
    {
      name,
      remoteOnly ? false,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        if [ "$#" -eq 0 ]; then
          echo "Usage: ${name} <command> [args...]" >&2
          exit 2
        fi

        export NIX_CONFIG="''${NIX_CONFIG:-}
        builders = ${builder}
        builders-use-substitutes = true
        ${lib.optionalString remoteOnly "max-jobs = 0"}"

        exec "$@"
      '';
    };
in
{
  home.packages = [
    (mkPannuWrapper { name = "with-pannu"; })
    (mkPannuWrapper {
      name = "on-pannu";
      remoteOnly = true;
    })
  ];
}
