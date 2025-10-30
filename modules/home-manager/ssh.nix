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
    extraOptionOverrides = {
      # fallback to xterm-256color so ssh prompts don't go crazy
      SetEnv = "TERM=xterm-256color";
    }
    // (lib.optionalAttrs isDarwin { UseKeychain = "yes"; });
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        hashKnownHosts = false;
      };
      "pannu" = {
        hostname = "p.kalski.xyz";
        user = "kahlstrm";
      };
    };
  };
}
