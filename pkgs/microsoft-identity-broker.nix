# yoinked from https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/mi/microsoft-identity-broker/package.nix
{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  jnr-posix,
  makeWrapper,
  zip,
  nixosTests,
  bash,
}:
let
  pkgs-old = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
    sha256 = "0zydsqiaz8qi4zd63zsb2gij2p614cgkcaisnk11wjy3nmiq0x1s";
  }) { system = "x86_64-linux"; };
  openjdk11 = pkgs-old.openjdk11.override {
    enableJavaFX = true;
    openjfx = pkgs-old.openjfx11.override {
      withWebKit = true;
    };
  };
in
stdenv.mkDerivation rec {
  pname = "microsoft-identity-broker";
  version = "2.0.1";

  src = fetchurl {
    url = "https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/microsoft-identity-broker/microsoft-identity-broker_${version}_amd64.deb";
    hash = "sha256-v/FxtdvRaUHYqvFSkJIZyicIdcyxQ8lPpY5rb9smnqA=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    openjdk11
    zip
  ];

  buildPhase = ''
    runHook preBuild

    rm opt/microsoft/identity-broker/lib/jnr-posix-3.1.4.jar
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/microsoft-identity-broker
    cp -a opt/microsoft/identity-broker/lib/* $out/lib/microsoft-identity-broker
    cp -a usr/* $out
    for jar in $out/lib/microsoft-identity-broker/*.jar; do
      classpath="$classpath:$jar"
    done
    classpath="$classpath:${jnr-posix}/share/java/jnr-posix-${jnr-posix.version}.jar"
    mkdir -p $out/bin
    makeWrapper ${openjdk11}/bin/java $out/bin/microsoft-identity-broker \
      --add-flags "-classpath $classpath com.microsoft.identity.broker.service.IdentityBrokerService" \
      --add-flags "-verbose"
    makeWrapper ${openjdk11}/bin/java $out/bin/microsoft-identity-device-broker \
      --add-flags "-verbose" \
      --add-flags "-classpath $classpath" \
      --add-flags "com.microsoft.identity.broker.service.DeviceBrokerService" \
      --add-flags "save"

    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace \
      $out/lib/systemd/user/microsoft-identity-broker.service \
      $out/lib/systemd/system/microsoft-identity-device-broker.service \
      $out/share/dbus-1/system-services/com.microsoft.identity.devicebroker1.service \
      $out/share/dbus-1/services/com.microsoft.identity.broker1.service \
      --replace \
        ExecStartPre=sh \
        ExecStartPre=${bash}/bin/sh \
      --replace \
        ExecStartPre=!sh \
        ExecStartPre=!${bash}/bin/sh \
      --replace \
        /opt/microsoft/identity-broker/bin/microsoft-identity-broker \
        $out/bin/microsoft-identity-broker \
      --replace \
        /opt/microsoft/identity-broker/bin/microsoft-identity-device-broker \
        $out/bin/microsoft-identity-device-broker \
      --replace \
        /usr/lib/jvm/java-11-openjdk-amd64 \
        ${openjdk11}/bin/java
  '';

  passthru = {
    updateScript = ./update.sh;
    tests = { inherit (nixosTests) intune; };
  };

  meta = {
    description = "Microsoft Authentication Broker for Linux";
    homepage = "https://www.microsoft.com/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ rhysmdnz ];
  };
}
