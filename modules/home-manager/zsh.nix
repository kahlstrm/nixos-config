{ nixosConfigLocation }:
{
  lib,
  isDarwin,
  isLinux,
  guiEnabled,
  flakeRoot,
  pkgs,
  ...
}:
let

  zsh-custom = import (flakeRoot + /pkgs/zsh-custom) { inherit pkgs; };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      PAGER = "less -FiRSwX";
      EDITOR = "nvim";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
    };

    shellAliases = {
      ghb = "gh browse";
      ghco = "gh pr checkout";
      ghprv = "gh pr view --web";
      copilot = "gh copilot";
      vim = "nvim";
      ls = "ls --color=auto";
      rg = "rg --hidden --glob '!.git'";
      cat = "bat --style plain --paging=never";
      dcup = "docker compose up";
      dcdown = "docker compose down";
      # used by git-extended oh-my-zsh plugin
      dotfiles = "git --git-dir ${nixosConfigLocation}/.git --work-tree ${nixosConfigLocation}";
      aliasgrep = "alias | rg";
      pollama = "OLLAMA_HOST=https://ollama.p.kalski.xyz ollama";
      nix-ld-enable = "export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH";
      claudec = "claude --continue";
      clauder = "claude --resume";
      codex = "codex --sandbox danger-full-access --ask-for-approval untrusted --enable web_search_request -m gpt-5.1 -c model_reasoning_effort=\"high\"";
      codexc = "codex resume --last";
      codexr = "codex resume";
    }
    // lib.optionalAttrs (isLinux && guiEnabled) {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "terraform"
        "docker"
        "kubectl"
      ]
      ++ zsh-custom.plugins;
      theme = zsh-custom.theme;
      # https://github.com/ohmyzsh/ohmyzsh/wiki/Customization
      custom = "${zsh-custom.out}";
    };
    # TODO: move more stuff from .zshrc/.zprofile here
  };

  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '')
    (lib.optionalString isDarwin ''
      eval "$(mise activate --shims zsh)"
    '')
    (
      if isDarwin then
        ''
          listport() {
             if [ ! -z "$1" ]; then
                 lsof -nP -iTCP:$1 -sTCP:LISTEN
                 return
             fi
             lsof -nP -iTCP -sTCP:LISTEN
          }
        ''
      else
        ''
          listport() {
             if [ ! -z "$1" ]; then
                 ss -tnlp | grep ":$1 "
                 return
             fi
             ss -tnlp
          }
        ''
    )
    ''
      ssm-connect() {
        local instance_id
        instance_id=$(aws ec2 describe-instances \
          --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId, Tags[?Key==`Name`].Value|[0]]' \
          --output text | fzf | awk '{print $1}')
        [ -n "$instance_id" ] && aws ssm start-session --target "$instance_id"
      }
    ''
    ''
      PATH=$PATH:$HOME/.npm/bin
      PATH=$PATH:$(go env GOPATH)/bin
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
    ''
  ];
}
