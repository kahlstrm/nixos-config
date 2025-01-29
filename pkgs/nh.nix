# yoinked from https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/nh/nh/package.nix
# modified for 4.0.0
# 4.0.0 has native darwin support, add overlay until 4.0.0 released.
{
  stdenv,
  lib,
  rustPlatform,
  installShellFiles,
  makeBinaryWrapper,
  darwin,
  fetchFromGitHub,
  nix-update-script,
  nvd,
  nix-output-monitor,
}:
let
  version = "4.0.0-beta.8";
  runtimeDeps = [
    nvd
    nix-output-monitor
  ];
in
rustPlatform.buildRustPackage {
  inherit version;
  pname = "nh";

  src = fetchFromGitHub {
    owner = "viperML";
    repo = "nh";
    rev = "refs/tags/v${version}";
    hash = "sha256-gNmu5trAOoWOo1nlSr0i0BOw4AnVmsbI1eG0WjMdvZU=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  preFixup = ''
    mkdir completions
    $out/bin/nh completions bash > completions/nh.bash
    $out/bin/nh completions zsh > completions/nh.zsh
    $out/bin/nh completions fish > completions/nh.fish

    installShellCompletion completions/*
  '';

  postFixup = ''
    wrapProgram $out/bin/nh \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';

  cargoHash = "sha256-W6QG2F4PXFeEB0TMTZtsfe8I+8iFmfdbAy90v0OWUcc=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Yet another nix cli helper";
    homepage = "https://github.com/viperML/nh";
    license = lib.licenses.eupl12;
    mainProgram = "nh";
    maintainers = with lib.maintainers; [
      drupol
      viperML
    ];
  };
}
