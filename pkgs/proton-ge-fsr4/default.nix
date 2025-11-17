{
  pkgs ? import <nixpkgs> { },
}:
let
  fsrVersion = "68840348eb8000";
  fsrDll = pkgs.fetchurl {
    url = "https://download.amd.com/dir/bin/amdxcffx64.dll/${fsrVersion}/amdxcffx64.dll";
    sha256 = "sha256-LUtfuOi1+eMwwcN2mJEyob4Yea8gu3+SRCxErQKvhvs="; # fix hash
    curlOpts = "--referer https://support.amd.com";
  };
in
(pkgs.proton-ge-bin.override { steamDisplayName = "GE-Proton FSR"; }).overrideAttrs (old: {
  installPhase = ''
    runHook preInstall

    # Make it impossible to add to an environment. You should use the appropriate NixOS option.
    # Also leave some breadcrumbs in the file.
    echo "${old.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    cp -a $src/* $steamcompattool
    chmod -R +w $steamcompattool

    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p $steamcompattool/files/lib/wine/amdprop
    cp ${fsrDll} $steamcompattool/files/lib/wine/amdprop/amdxcffx64.dll
    echo "${fsrVersion}" > $steamcompattool/files/lib/wine/amdprop/amdxcffx64_version
  '';

  preFixup = (old.preFixup or "") + ''
    substituteInPlace "$steamcompattool/proton" \
      --replace-fail 'self.download_file(fsr_dll_url, fsr_dll)' 'pass  # nix: keep existing FSR4 dll' \
      --replace-fail 'with open(version_file, "w") as file:' 'pass  # nix: keep existing FSR4 dll' \
      --replace-fail 'file.write(version + "\n")' '# file.write(version + "\n")'
  '';
})
