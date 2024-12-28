{
  currentSystemEmail,
  currentSystemName,
  currentSystemUser,
  ...
}:
{
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  # disabled for now, seems broken on darwin
  # manpager = (
  #   pkgs.writeShellScriptBin "manpager" (
  #     if isDarwin then
  #       ''
  #         sh -c 'col -bx | bat -l man -p'
  #       ''
  #     else
  #       ''
  #         cat "$1" | col -bx | bat --language man --style plain
  #       ''
  #   )
  # );

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
    # Remove history data we don't want to see
    HISTIGNORE = "pwd:ls:cd";
    NIXNAME = currentSystemName;
    PAGER = "less -FirSwX";
    # MANPAGER = "${manpager}/bin/manpager";
  };

  home.file =
    {
      # ".inputrc".source = ./inputrc;
    }
    // (
      if isDarwin then
        {
        }
      else
        { }
    );

  # TODO: determine if I want to use immutable or mutable symlinks for configs
  # mutable symlinks are good when I'm still configuring stuff in e.g. nvim
  xdg.configFile =
    {
      "ghostty/config".text = builtins.readFile ./ghostty;
    }
    // (
      if isDarwin then
        {
        }
      else
        { }
    )
    // (
      if isLinux then
        {
        }
      else
        { }
    );

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
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "terraform"
          "docker"
        ];
        theme = "af-magic";
      };
      # TODO: move more stuff from .zshrc/.zprofile here
      initExtraFirst = ''
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
        export PATH=$HOME/.local/share/bin:$PATH
        eval "$(mise activate --shims zsh)"
      '';
    };

    neovim = {
      enable = true;
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
        (lib.mkIf pkgs.stdenv.hostPlatform.isLinux "/home/${currentSystemUser}/.ssh/config_external")
        (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Users/${currentSystemUser}/.ssh/config_external")
      ];
      addKeysToAgent = "yes";
      extraOptionOverrides = {
        # fallback to xterm-256color so ssh prompts don't go crazy
        SetEnv = "TERM=xterm-256color";
      } // (lib.optionals isDarwin { UseKeychain = "yes"; });

    };

    # TODO: find out how to tmux :D
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
