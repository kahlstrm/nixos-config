{ ... }:
{
  programs.ssh.knownHosts = {
    "jet.kalski.xyz" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuFoL+bSI5l0VM9kkl6Fj5g2yMor9osv2rnTNLz3KKR";
    };
    "p.kalski.xyz" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk8+06RzXtg+i6G8YZBB4YPHB55FyhtpgjELqU5bYMF";
    };
  };
}
