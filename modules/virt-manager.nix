{ spiceUSBRedirectionEnabled }:
{
  currentSystemUser,
  ...
}:
{
  # https://nixos.wiki/wiki/Virt-manager
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ currentSystemUser ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = spiceUSBRedirectionEnabled;
}
