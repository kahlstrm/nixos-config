# Secrets

`secrets.nix` maps encrypted files to host and administrator public keys.
The CLI is installed with the development packages. From this directory:

```sh
agenix -e headscale-oidc.age # edit
agenix -d headscale-oidc.age # view
agenix -r # after changing recipients
```

Create listed files before rekeying. Commit ciphertext only; avoid editor backups
of plaintext. Declare files with `age.secrets` on their consuming host and pass
the runtime path to services—never read decrypted values into Nix settings.

Back up the administrator key for recovery after host replacement. Removing a
recipient cannot revoke old Git history; rotate credentials if a key is compromised.
