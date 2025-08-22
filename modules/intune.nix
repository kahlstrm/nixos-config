{ lib, ... }:
{
  services.intune.enable = true;
  systemd.user.timers.intune-agent.wantedBy = [ "graphical-session.target" ];
  systemd.sockets.intune-daemon.wantedBy = [ "sockets.target" ];
  services.gnome.gnome-keyring.enable = lib.mkForce true;
  # for debugging
  programs.seahorse.enable = true;
}
