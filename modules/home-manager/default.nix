{
  isDarwin,
  isLinux,
  nix-index-database,
  lib,
  config,
  flakeRoot,
  useOutOfStoreSymlink,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  nixosConfigLocation = "${homeDirectory}/nixos-config";
  configPath = flakeRoot + /config;
in
{
  imports = [
    nix-index-database.homeModules.nix-index
    {
      programs.nix-index-database.comma.enable = true;
      programs.nix-index.enableZshIntegration = false;
      programs.nix-index.enableBashIntegration = false;
      programs.nix-index.enableFishIntegration = false;
    }
    (import ./neovim.nix { inherit nixosConfigLocation; })
    (import ./zsh.nix { inherit nixosConfigLocation; })
    (import ./nh.nix { inherit nixosConfigLocation; })
    ./git.nix
    ./ssh.nix
    ./btop.nix
  ];
  home.stateVersion = "24.11";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # dotfiles
  #---------------------------------------------------------------------

  home.file = {
    ".claude/CLAUDE.md".source = configPath + /AGENTS.md;
    ".gemini/GEMINI.md".source = configPath + /AGENTS.md;
  }
  // (lib.optionalAttrs isDarwin { } // (lib.optionalAttrs isLinux { }));

  xdg.configFile = {
    "opencode/AGENTS.md".source = configPath + /AGENTS.md;
    "opencode/settings.json".source =
      if useOutOfStoreSymlink then
        # Create a directory symlink to .config/nvim, allowing mutable editing of config
        config.lib.file.mkOutOfStoreSymlink "${nixosConfigLocation}/config/opencode/opencode.json"
      else
        (configPath + /opencode/opencode.json);
    "ghostty".source = configPath + /ghostty;
  }
  // (lib.optionalAttrs isDarwin {
    "linearmouse".source = configPath + /linearmouse;
    "mise".source = configPath + /mise;
    # linearmouse will overwrite the file when changed in config.
    # Changes should be made via Nix config.
    # https://github.com/nix-community/home-manager/issues/3090
    "linearmouse".force = true;
  })
  // (lib.optionalAttrs isLinux {
  });

  programs = {

    fzf.enable = true;

    # TODO: find out how to tmux
    # tmux = {
    #   enable = true;
    #   terminal = "xterm-256color";
    #   shortcut = "l";
    #   secureSocket = false;
    #   mouse = true;
    #
    #   extraConfig = ''
    #     set -ga terminal-overrides ",*256col*:Tc"
    #
    #     set -g @dracula-show-battery false
    #     set -g @dracula-show-network false
    #     set -g @dracula-show-weather false
    #
    #     bind -n C-k send-keys "clear"\; send-keys "Enter"
    #
    #     run-shell ${sources.tmux-pain-control}/pain_control.tmux
    #     run-shell ${sources.tmux-dracula}/dracula.tmux
    #   '';
    # };
  };

}
