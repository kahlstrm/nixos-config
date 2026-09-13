{ lib, ... }:

let
  disabledSkills = [ "browser:control-in-app-browser" ];
  skillConfig = lib.concatMapStringsSep ", " (
    name: "{ name = ${builtins.toJSON name}, enabled = false }"
  ) disabledSkills;
  codex = lib.escapeShellArgs [
    "command"
    "codex"
    "-c"
    "skills.config=[${skillConfig}]"
  ];
in
{
  programs.zsh.shellAliases = {
    inherit codex;
    codexc = "${codex} resume --last";
    codexr = "${codex} resume";
  };
}
