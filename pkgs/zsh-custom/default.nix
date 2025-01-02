{
  pkgs ? import <nixpkgs> { },
}:
# https://github.com/ohmyzsh/ohmyzsh/wiki/Customization
let
in
{
  out = pkgs.stdenv.mkDerivation {
    name = "zsh-customs";

    src = ./.;

    nativeBuildInputs = [ pkgs.zsh ];
    phases = [ "buildPhase" ];
    buildPhase = ''
      mkdir -p $out/themes
      cp $src/af-magic-customized.zsh-theme $out/themes/af-magic-customized.zsh-theme

      mkdir -p $out/plugins
      mkdir -p $out/plugins/git-extended
      zsh -c "
        source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh
        source $src/create-extended-git.zsh > $out/plugins/git-extended/git-extended.plugin.zsh
      "
    '';
  };
  plugins = [ "git-extended" ];
  theme = "af-magic-customized";
}
