# Headscale Google login

Manage the client and consent screen manually in Google Auth Platform:
[Terraform lacks this client type](https://github.com/hashicorp/terraform-provider-google/issues/16452).
`google_iam_oauth_client` is for Workforce Identity Federation, not Google Sign-In.

1. Select the intended project; use an **External** audience for personal accounts.
2. Create a **Web application** client named `Headscale`; set its redirect URI to
   `https://head.kalski.xyz/oidc/callback` (`server_url` + `/oidc/callback`).
3. Edit `secrets/headscale-oidc.age` with [agenix](../../secrets/README.md).
   Keep the entire configuration under `oidc`, including client ID, secret, and `allowed_users`.
   Never commit downloaded credentials or share secrets in chat.
4. Include issuer `https://accounts.google.com`,
   client ID, scopes `openid`, `profile`, `email`, PKCE `S256`, and verified email required.
   Keep `allowed_users` nonempty; startup rejects missing credentials or an empty allowlist.

Example decrypted contents of `headscale-oidc.age` (replace the placeholders in the agenix editor):

```json
{
  "oidc": {
    "issuer": "https://accounts.google.com",
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "client_secret": "YOUR_CLIENT_SECRET",
    "scope": ["openid", "profile", "email"],
    "pkce": { "enabled": true, "method": "S256" },
    "email_verified_required": true,
    "allowed_users": ["you@example.com"]
  }
}
```

[Headscale](default.nix) merges the decrypted block at startup into
`/run/headscale/config.json` (owner-only). Deploy after editing; no plaintext enters the Nix store.
The allowlist controls enrollment; ACLs separately control network access.

No additional infrastructure resources are needed with the existing project and endpoint.
See [Headscale's OIDC guide](https://headscale.net/stable/ref/oidc/#google-oauth) for details.
