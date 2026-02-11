{
  lib,
  pkgs,
  currentSystemEmail,
  personalEmail,
  ...
}:
let
  isPersonalEmailSet = personalEmail != null && personalEmail != "";
  isDifferentEmail = isPersonalEmailSet && (personalEmail != currentSystemEmail);
  difft-wrapper = pkgs.writeShellScript "difft-wrapper" ''
    if [ -n "$GIT_PAGER_IN_USE" ]; then
      exec ${lib.getExe pkgs.difftastic} "$@"
    else
      diff -u --label "a/$1" --label "b/$1" "$2" "$5"
      exit 0
    fi
  '';
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

  programs.difftastic.enable = true;
  programs.git.settings.diff.external = toString difft-wrapper;

  programs.mergiraf.enable = true;

}
