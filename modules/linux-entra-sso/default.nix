{ pkgs, ... }:
let
  linux-entra-sso = import ./package.nix { inherit pkgs; };
in
{
  programs.firefox.nativeMessagingHosts.packages = [ linux-entra-sso ];
  programs.firefox.policies.ExtensionSettings."linux-entra-sso@example.com" = {
    installation_mode = "normal_installed";
    install_url = "https://github.com/siemens/linux-entra-sso/releases/download/v${linux-entra-sso.version}/linux_entra_sso-${linux-entra-sso.version}.xpi";
  };

  environment.etc."opt/chrome/native-messaging-hosts/linux_entra_sso.json".source =
    "${linux-entra-sso}/etc/opt/chrome/native-messaging-hosts/linux_entra_sso.json";

  environment.etc."opt/chrome/policies/managed/linux-entra-sso.json".text = builtins.toJSON {
    ExtensionSettings.jlnfnnolkbjieggibinobhkjdfbpcohn = {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
}
