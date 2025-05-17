{ currentSystemUser, ... }:
{
  system.primaryUser = currentSystemUser;
  # Allow Sudo with Touch ID.
  security.pam.services.sudo_local.touchIdAuth = true;

}
