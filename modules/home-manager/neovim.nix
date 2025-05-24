{ nixosConfigLocation }:
{
  config,
  pkgs-unstable,
  ...
}:
let

in
{
  xdg.configFile."nvim".source =
    # Create a directory symlink to .config/nvim, allowing mutable editing of config
    config.lib.file.mkOutOfStoreSymlink "${nixosConfigLocation}/config/nvim";
  programs.neovim = {
    enable = true;
    vimdiffAlias = true;
    package = pkgs-unstable.neovim-unwrapped;
    # as we manage Neovim plugins outside of Nix,
    # some plugins (mainly Treesitter) require gcc
    extraPackages = with pkgs-unstable; [
      clang
      gnumake
      python3
      nodejs
      nixd
      nixfmt-rfc-style
      gleam
      dart
      ripgrep
    ];
  };
}
