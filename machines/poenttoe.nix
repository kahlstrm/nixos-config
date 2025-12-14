{
  currentSystemUser,
  ...
}:
{
  imports = [
    ./hardware/poenttoe.nix
  ];

  networking.hostName = "poenttoe";

  # OpenSSH for remote administration
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false; # Enabled to allow password login after you set one
  };

  # Match infected config defaults
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # ZeroTier
  services.zerotierone.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    description = "Kalle Ahlstrom";
    extraGroups = [
      "wheel"
    ];
  };

  system.stateVersion = "23.11";
}
