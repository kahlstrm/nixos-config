{
  pkgs,
  currentSystemUser,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/zima.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.fwupd.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # OpenSSH for remote administration
  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    description = "Kalle Ahlstrom";
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
