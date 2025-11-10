{ spiceUSBRedirectionEnabled }:
{
  currentSystemUser,
  ...
}:
{
  # https://nixos.wiki/wiki/Virt-manager
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ currentSystemUser ];
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
    onBoot = "ignore";
  };
  virtualisation.spiceUSBRedirection.enable = spiceUSBRedirectionEnabled;
}
