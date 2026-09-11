{ ... }:
{
  home.file.".codex/personal.config.toml".source = ../../config/codex/personal.config.toml;

  programs.zsh.shellAliases = {
    codex = "codex --profile personal";
    codexc = "codex resume --last";
    codexr = "codex resume";
  };
}
