{
  lib,
  isDarwin,
  config,
  ...
}:
{
  programs.ssh = {
    enable = true;
    includes = [
      "${config.home.homeDirectory}/.ssh/config_external"
    ];
    addKeysToAgent = "yes";
    extraOptionOverrides = {
      # fallback to xterm-256color so ssh prompts don't go crazy
      SetEnv = "TERM=xterm-256color";
    }
    // (lib.optionalAttrs isDarwin { UseKeychain = "yes"; });
    matchBlocks = {
      "pannu" = {
        hostname = "p.kalski.xyz";
        user = "kahlstrm";
      };
    };
  };
}
