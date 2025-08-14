{
  hasAmdGPU ? false,
}:
{
  currentSystemUser,
  pkgs,
  lib,
  isStable,
  ...
}:
let
  fsrVersion = "67D435F7d97000";
  fsrDll = pkgs.fetchurl {
    url = "https://download.amd.com/dir/bin/amdxcffx64.dll/${fsrVersion}/amdxcffx64.dll";
    sha256 = "sha256-OuTTllFAwQjzKJXbRhV7Ma15AgFo1U+EHFYqH9/EqVw="; # fix hash
    curlOpts = "--referer https://support.amd.com";
  };

  proton-ge-bin-fsr4 =
    (pkgs.proton-ge-bin.override { steamDisplayName = "GE-Proton FSR"; }).overrideAttrs
      (old: {
        installPhase = ''
          runHook preInstall

          # Make it impossible to add to an environment. You should use the appropriate NixOS option.
          # Also leave some breadcrumbs in the file.
          echo "${old.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

          mkdir $steamcompattool
          cp -a $src/* $steamcompattool
          chmod -R +w $steamcompattool

          rm $steamcompattool/compatibilitytool.vdf
          cp $src/compatibilitytool.vdf $steamcompattool

          runHook postInstall
        '';

        postInstall = ''
          mkdir -p $steamcompattool/files/lib/wine/amdprop
          cp ${fsrDll} $steamcompattool/files/lib/wine/amdprop/amdxcffx64.dll
          echo "${fsrVersion}" > $steamcompattool/files/lib/wine/amdprop/amdxcffx64_version
        '';

        preFixup = (old.preFixup or "") + ''
          substituteInPlace "$steamcompattool/proton" \
            --replace-fail 'if not version_match:' '# if not version_match:' \
            --replace-fail 'with open(g_proton.lib_dir + "wine/amdprop/amdxcffx64_version", "w") as file:' '# with open(g_proton.lib_dir + "wine/amdprop/amdxcffx64_version", "w") as file:' \
            --replace-fail 'file.write(versions[1] + "\n")' '# file.write(versions[1] + "\n")'
        '';
      });
  compatPaths = lib.makeSearchPathOutput "steamcompattool" "" (
    with pkgs;
    [
      proton-ge-bin
      proton-ge-bin-fsr4
    ]
  );
in
{
  users.groups."steam-machine" = { };
  users.users."steam-machine" = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "video"
      "input"
      "games"
    ];
    group = "steam-machine";
    packages = with pkgs; [
      firefox
      mpv
    ];
  };

  # if there is disk with label 'games', mounts it
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  # and makes it group writeable and changes group to 'games'
  systemd.services.setup-games-perms = {
    after = [ "mnt-games.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      chgrp games /mnt/games
      chmod 775 /mnt/games
      chmod g+s /mnt/games
    '';
  };

  users.groups.games = { };
  boot.kernelModules = lib.optionals (!isStable) [ "ntsync" ];

  users.users."${currentSystemUser}".extraGroups = [ "games" ];
  services.desktopManager.plasma6.enable = true;

  jovian = {
    hardware.has.amd.gpu = hasAmdGPU;
    hardware.amd.gpu.enableBacklightControl = false;
    steam = {
      autoStart = true;
      enable = true;
      user = "steam-machine";
      desktopSession = "plasma";
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = compatPaths;
      };
    };
    steamos = {
      useSteamOSConfig = false;
      enableBluetoothConfig = true;
      enableDefaultCmdlineConfig = true;
      enableProductSerialAccess = true;
      enableSysctlConfig = true;
    };
  };

  programs.steam.localNetworkGameTransfers.openFirewall = true;
  # Add sunshine game streaming
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      origin_web_ui_allowed = "pc";
    };
  };

  programs.alvr.enable = true;
  programs.alvr.openFirewall = true;
  # doesn't build with 6.15 kernel currently, and not in use
  # hardware.xone.enable = true;

}
