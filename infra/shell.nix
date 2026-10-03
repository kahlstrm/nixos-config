{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {
  # nativeBuildInputs is usually what you want -- tools you need to run
  nativeBuildInputs = with pkgs; [
    google-cloud-sdk
    opentofu
    python3
    jq
    vim
    just
    talosctl
    kubectl
  ];
  shellHook = ''
    alias terraform=tofu
  '';
}
