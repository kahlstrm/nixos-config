{
  currentSystemEmail,
  ...
}:
{
  lib,
  pkgs,
  config,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  homeDirectory = config.home.homeDirectory;
  nixosConfigLocation = "${homeDirectory}/nixos-config";
in
{
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
      "ghostty/config".source = ../config/ghostty;
      # create a directory symlink to .config/nvim, allowing mutable editing of config
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/nixos-config/config/nvim";
    }
    // (lib.optionalAttrs isDarwin {
      "linearmouse/linearmouse.json".source = ../config/linearmouse.json;
      # linearmouse will overwrite the file when changed in config.
      # Changes should be made via Nix config.
      # https://github.com/nix-community/home-manager/issues/3090
      "linearmouse/linearmouse.json".force = true;
    })
    // (lib.optionalAttrs isLinux { });
  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ghb = "gh browse";
        copilot = "gh copilot";
        vim = "nvim";
        ls = "ls --color=auto";
        cat = "bat --style plain --paging=never";
        grsp = "git restore --patch";
        grssp = "git restore --source --patch";
        grstp = "git restore --staged --patch";
        gwips = "git commit --no-verify --no-gpg-sign --message \"--wip-- [skip ci]\"'";
        grbi5 = "git rebase --interactive HEAD~5";
        # TODO: make custom derivation that creates "dotfiles"
        # aliases for all git aliased commands
        dotfiles = "git --git-dir ${nixosConfigLocation}/.git --work-tree ${nixosConfigLocation}";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "terraform"
          "docker"
        ];
        theme = "af-magic-customized";
        # https://github.com/ohmyzsh/ohmyzsh/wiki/Customization
        custom = "${../config/oh-my-zsh-custom}";
      };
      # TODO: move more stuff from .zshrc/.zprofile here
      initExtraFirst = ''
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
        eval "$(mise activate --shims zsh)"
      '';
      initExtra = ''
        # TODO: not sure if works on Linux as-is
        function listport(){
          if [ ! -z "$1" ]; then
            lsof -nP -iTCP:$1 -sTCP:LISTEN
            return
          fi
          lsof -nP -iTCP -sTCP:LISTEN
        }

        ghco(){
          gh pr list | fzf | awk '{print $1}' | xargs gh pr checkout
        }

        ghrl(){
          if [ -z "$1" ]; then
            echo 'Please provide github username'
            return
          fi
          if [ -z "$2" ] ; then
            gh repo list $1 -L 9999 --json name -q '.[].name'
            return
          fi
          gh repo list $1 -L 9999 --json name -q '.[].name' | grep $2
        }
        if [ -f ~/.zshrc_external ]; then
          source ~/.zshrc_external
        fi
      '';
    };

    neovim = {
      enable = true;
      vimdiffAlias = true;
      # as we manage Neovim plugins outside of Nix,
      # some plugins (mainly Treesitter) require gcc
      extraPackages = [ pkgs.gcc ];
    };

    fzf = {
      enable = true;
    };

    git = {
      enable = true;
      ignores = [
        "*.swp"
        ".DS_STORE"
      ];
      userName = "Kalle Ahlström";
      userEmail = currentSystemEmail;
      lfs = {
        enable = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core = {
          autocrlf = "input";
          pager = "delta";
        };
        interactive.diffFilter = "delta --color-only";
        delta = {
          navigate = true;
        };
        merge.conflictstyle = "zdiff3";
        pull.ff = "only";
        rebase.autoStash = true;
        rerere.enabled = true;
      };
    };

    ssh = {
      enable = true;
      includes = [
        "${homeDirectory}/.ssh/config_external"
      ];
      addKeysToAgent = "yes";
      extraOptionOverrides = {
        # fallback to xterm-256color so ssh prompts don't go crazy
        SetEnv = "TERM=xterm-256color";
      } // (lib.optionalAttrs isDarwin { UseKeychain = "yes"; });

    };
    # nix cli helper https://github.com/viperML/nh
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 10";
      # automatically sets up FLAKE environment variable
      flake = nixosConfigLocation;
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
