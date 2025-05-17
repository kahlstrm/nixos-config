{ lib, isDarwin, ... }:
{
  programs.zsh.initExtraFirst = ''
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
  programs.zsh.initExtra =
    (lib.optionalString isDarwin ''
      eval "$(mise activate --shims zsh)"
    '')
    + ''

      PATH=$PATH:$HOME/.npm/bin
      # TODO: not sure if works on Linux as-is
      function listport(){
        if [ ! -z "$1" ]; then
          lsof -nP -iTCP:$1 -sTCP:LISTEN
          return
        fi
        lsof -nP -iTCP -sTCP:LISTEN
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
}
