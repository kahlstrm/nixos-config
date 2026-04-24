{ nixosConfigLocation }:
{
  config,
  pkgs-unstable,
  useOutOfStoreSymlink,
  flakeRoot,
  ...
}:
let
  pkgs = pkgs-unstable;
in
{
  xdg.configFile."nvim".source =
    if useOutOfStoreSymlink then
      # Create a directory symlink to .config/nvim, allowing mutable editing of config
      config.lib.file.mkOutOfStoreSymlink "${nixosConfigLocation}/config/nvim"
    else
      (flakeRoot + /config/nvim);

  programs.neovim = {
    enable = true;
    vimdiffAlias = true;
    package = pkgs.neovim-unwrapped;
    # https://github.com/nix-community/home-manager/pull/9028
    sideloadInitLua = true;
    # as we manage Neovim plugins outside of Nix,
    # some plugins (mainly Treesitter) require C compiler
    extraPackages = with pkgs; [
      clang
      gnumake
      tree-sitter
      python3
      nodejs_24
      nixd
      nixfmt
      golangci-lint
      ripgrep
      jdk
    ];
  };
}
