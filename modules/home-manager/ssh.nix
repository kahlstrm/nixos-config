{
  lib,
  isDarwin,
  config,
  ...
}:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "${config.home.homeDirectory}/.ssh/config_external"
    ];
    extraOptionOverrides = lib.optionalAttrs isDarwin { UseKeychain = "yes"; };
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        hashKnownHosts = false;
        setEnv.TERM = "xterm-256color";
      };
      "pannu" = {
        hostname = "p.kalski.xyz";
        user = "kahlstrm";
      };
      "zima" = {
        hostname = "zima.kalski.xyz";
        user = "kahlstrm";
      };
      "poenttoe" = {
        hostname = "poenttoe.kalski.xyz";
        user = "kahlstrm";
      };
      "kuberack" = {
        hostname = "kuberack.networking.kalski.xyz";
      };
      "stationary" = {
        hostname = "stationary.networking.kalski.xyz";
      };
    };
  };
}
