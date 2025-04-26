{
  pkgs,
  lib,
  currentSystem,
  currentSystemUser,
  ...
}:

{
  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  services.spice-vdagentd.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # setup windowing environment
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
  };

  # Enable tailscale. We manually authenticate when we want with
  # "sudo tailscale up". If you don't use tailscale, you should comment
  # out or delete all of this.
  # services.tailscale.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    description = "Kalle Ahlstrom";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.

  environment.systemPackages = with pkgs; [
    # microsoft-edge
    rocmPackages.rocm-smi
  ];
  # Install firefox.
  programs.firefox.enable = true;
  # Enables native Wayland on Chromium/Electron based applications
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  # services.openssh.settings.PasswordAuthentication = true;
  # services.openssh.settings.PermitRootLogin = "no";

  # Enable flatpak. I don't use any flatpak apps but I do sometimes
  # test them so I keep this enabled.
  # services.flatpak.enable = true;

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;
}
