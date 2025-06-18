{ nixosConfigLocation }:
{
  config,
  pkgs-unstable,
  useOutOfStoreSymlink,
  flakeRoot,
  ...
}:
let

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
    package = pkgs-unstable.neovim-unwrapped;
    # as we manage Neovim plugins outside of Nix,
    # some plugins (mainly Treesitter) require C compiler
    extraPackages = with pkgs-unstable; [
      clang
      gnumake
      python3
      nodejs
      nixd
      nixfmt-rfc-style
      dart
      ripgrep
      jdk
    ];
  };
}
