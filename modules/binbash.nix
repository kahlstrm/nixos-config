{ pkgs, ... }:
{
  # create /bin/bash
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];
}
