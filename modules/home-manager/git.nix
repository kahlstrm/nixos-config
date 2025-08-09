{
  lib,
  currentSystemEmail,
  personalEmail,
  ...
}:
let
  isPersonalEmailSet = personalEmail != null && personalEmail != "";
  isDifferentEmail = isPersonalEmailSet && (personalEmail != currentSystemEmail);
  makePersonalGitDirPathConfigs =
    gitDirPaths:
    map (gitdirPath: {
      condition = "gitdir:${gitdirPath}";
      contents = {
        user.email = personalEmail;
      };
    }) gitDirPaths;
in
{
  programs.git = {
    enable = true;
    ignores = [
      "*.swp"
      ".DS_STORE"
      "CLAUDE.md"
      "GEMINI.md"
      "AGENTS.md"
    ];
    delta = {
      enable = true;
      options = {
        navigate = true;
      };
    };
    userName = "Kalle Ahlström";
    userEmail = currentSystemEmail;
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        autocrlf = "input";
      };
      branch.sort = "-committerdate";
      merge.conflictstyle = "zdiff3";
      pull.ff = "only";
      rebase.autoStash = true;
      rerere.enabled = true;
    };
    includes = lib.optionals isDifferentEmail (makePersonalGitDirPathConfigs [
      "~/nixos-config/"
      "~/infra/"
      "~/src/github/"
    ]);
  };
}
