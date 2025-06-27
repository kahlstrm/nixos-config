/*
  This contains various packages we want to overlay. Note that the
  other ".nix" files in this directory are automatically loaded.
*/
final: prev: {
  # this is how one would e.g. overlay the `microsoft-identity-broker` package with new package definition in ../pkgs/microsoft-identity-broker.nix
  # microsoft-identity-broker = final.callPackage ../pkgs/microsoft-identity-broker.nix { };
  # temporary fix for amdgpu
  linux-firmware = prev.linux-firmware.overrideAttrs (old: rec {
    pname = "linux-firmware";
    version = "20250624";
    src = prev.fetchFromGitLab {
      owner = "kernel-firmware";
      repo = "linux-firmware";
      rev = "b05fabcd6f2a16d50b5f86c389dde7a33f00bb81";
      hash = "sha256-AvSsyfKP57Uhb3qMrf6PpNHKbXhD9IvFT1kcz5J7khM=";
    };
  });
}
