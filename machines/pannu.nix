{
  pkgs,
  currentSystemUser,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware/pannu.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.${currentSystemUser} = {
    isNormalUser = true;
    description = "Kalle Ahlstrom";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      btop-rocm
    ];
  };

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
  ];

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # need to wait for 6.4.0+ rocm packages
  # services.ollama = {
  #   enable = true;
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   acceleration = "rocm";
  #   environmentVariables = {
  #     OLLAMA_FLASH_ATTENTION = "1";
  #     # currently not working for Gemma3 https://github.com/ggml-org/llama.cpp/issues/12352#issuecomment-2727452955
  #     # OLLAMA_KV_CACHE_TYPE = "q8_0";
  #   };
  #   home = "/var/lib/ollama";
  # };

  # services.open-webui = {
  #   enable = true;
  #   host = "0.0.0.0";
  #   openFirewall = true;
  #   environment = {
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
  #   };
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [
  #   8080
  #   11434
  # ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.05"; # Did you read the comment?
}
