{ currentSystemEmail, pkgs, ... }:
let

  delta = "${pkgs.delta}/bin/delta";
in
{
  programs.git = {
    enable = true;
    ignores = [
      "*.swp"
      ".DS_STORE"
      "CLAUDE.md"
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
        pager = delta;
      };
      interactive.diffFilter = "${delta} --color-only";
      delta = {
        navigate = true;
      };
      branch.sort = "-committerdate";
      merge.conflictstyle = "zdiff3";
      pull.ff = "only";
      rebase.autoStash = true;
      rerere.enabled = true;
    };
  };
}
