{
  isDarwin,
  isLinux,
  nix-index-database,
  lib,
  config,
  flakeRoot,
  ...
}:

let
  homeDirectory = config.home.homeDirectory;
  nixosConfigLocation = "${homeDirectory}/nixos-config";
  configPath = flakeRoot + /config;
in
{
  imports = [
    nix-index-database.hmModules.nix-index
    {
      programs.nix-index-database.comma.enable = true;
      programs.nix-index.enableZshIntegration = false;
      programs.nix-index.enableBashIntegration = false;
      programs.nix-index.enableFishIntegration = false;
    }
    (import ./neovim.nix { inherit configPath; })
    (import ./zsh.nix { inherit nixosConfigLocation; })
    (import ./nh.nix { inherit nixosConfigLocation; })
    ./git.nix
    ./ssh.nix
  ];
  home.stateVersion = "24.11";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };

  home.file = {
    # ".inputrc".source = ./inputrc;
  } // (lib.optionalAttrs isDarwin { } // (lib.optionalAttrs isLinux { }));

  xdg.configFile =
    {
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
  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
  programs = {

    fzf = {
      enable = true;
    };

    btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };

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
