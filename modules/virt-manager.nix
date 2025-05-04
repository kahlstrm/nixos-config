{ spiceUSBRedirectionEnabled }:
{
  currentSystemUser,
  pkgs,
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
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
    onBoot = "ignore";
  };
  virtualisation.spiceUSBRedirection.enable = spiceUSBRedirectionEnabled;
}
