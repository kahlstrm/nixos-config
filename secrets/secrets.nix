let
  administrator = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPp11x78hP1TOHinNlmZhPpVxBczbxjygYeTZB5pwOq+";
  poenttoe = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3Ej4EpcyblV2ULtqb9sCg8vM1zH96sy/eVjwEzv/l6";
in
{
  "headscale-oidc.age".publicKeys = [
    administrator
    poenttoe
  ];
}
