# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [
    "dm-snapshot"
    "amdgpu"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Enable mdadm for software RAID
  boot.swraid = {
    enable = true;
    mdadmConf = let
      telegramNotify = pkgs.callPackage ../../pkgs/mdadm-telegram-notify.nix { };
    in ''
      # mdadm will scan for arrays
      ARRAY /dev/md0 devices=/dev/sda,/dev/sdb
      PROGRAM ${telegramNotify}/bin/mdadm-telegram-notify
    '';
  };

  fileSystems."/mnt/raid" = {
    device = "/dev/md0";
    fsType = "ext4";
  };

  fileSystems."/mnt/wip" = {
    device = "/dev/disk/by-label/wip";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  fileSystems."/var/lib/ollama" = {
    device = "/dev/disk/by-label/ollama";
    fsType = "ext4";
  };

  environment.systemPackages = [ pkgs.mdadm ];

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # networking.interfaces.enp6s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
