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
      "/.claude/"
    ];
    lfs = {
      enable = true;
    };
    settings = {
      user = {
        name = "Kalle Ahlström";
        email = currentSystemEmail;
      };
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

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.mergiraf.enable = true;

}
