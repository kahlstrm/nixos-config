# Secrets

`secrets.nix` maps encrypted files to host and administrator public keys.
From this directory:

```sh
nix run ..#agenix -- -e headscale-oidc.age -i "$HOME/.ssh/id_ed25519"
nix run ..#agenix -- -r -i "$HOME/.ssh/id_ed25519" # after changing recipients
```

Create listed files before rekeying. Commit ciphertext only; avoid editor backups
of plaintext. Declare files with `age.secrets` on their consuming host and pass
the runtime path to services—never read decrypted values into Nix settings.

Back up the administrator key for recovery after host replacement. Removing a
recipient cannot revoke old Git history; rotate credentials if a key is compromised.
