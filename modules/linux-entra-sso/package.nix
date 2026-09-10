{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [
    ps.pygobject3
    ps.pydbus
  ]);
in
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "linux-entra-sso";
  version = "1.10.2";

  src = pkgs.fetchFromGitHub {
    owner = "siemens";
    repo = "linux-entra-sso";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JOqJorjcgPJiFIwzQXBPhcotrJY7KBHRzL3W4qtBVW8=";
  };

  dontBuild = true;
  makeFlags = [
    "RELEASE_TAG=v${finalAttrs.version}"
    "prefix=$(out)"
    "python3_bin=${python}/bin/python3"
    "firefox_nm_dir=$(out)/lib/mozilla/native-messaging-hosts"
    "chrome_nm_dir=$(out)/etc/opt/chrome/native-messaging-hosts"
    "chromium_nm_dir=$(out)/etc/chromium/native-messaging-hosts"
    "chrome_ext_dir=$(out)/share/google-chrome/extensions"
  ];

  postInstall = ''
    mkdir -p "$out/bin"
    ln -s "$out/libexec/linux-entra-sso/linux-entra-sso.py" "$out/bin/linux-entra-sso"
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ pkgs.jq ];
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/linux-entra-sso" --interactive --help > /dev/null
    for manifest in \
      "$out/lib/mozilla/native-messaging-hosts/linux_entra_sso.json" \
      "$out/etc/opt/chrome/native-messaging-hosts/linux_entra_sso.json" \
      "$out/etc/chromium/native-messaging-hosts/linux_entra_sso.json"; do
      test -x "$(jq -er '.path' "$manifest")"
      jq -e '.name == "linux_entra_sso" and .type == "stdio"' "$manifest" > /dev/null
    done
    jq -e '.allowed_origins == ["chrome-extension://jlnfnnolkbjieggibinobhkjdfbpcohn/"]' \
      "$out/etc/opt/chrome/native-messaging-hosts/linux_entra_sso.json" > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Browser native messaging host for Microsoft Entra ID SSO";
    homepage = "https://github.com/siemens/linux-entra-sso";
    license = pkgs.lib.licenses.mpl20;
    platforms = pkgs.lib.platforms.linux;
    mainProgram = "linux-entra-sso";
  };
})
