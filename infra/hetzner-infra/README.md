# hetzner-infra

Terraform layer for Hetzner Cloud resources.

## Bootstrap

1. Authenticate to GCP (Terraform backend + Secret Manager):

   ```bash
   gcloud auth application-default login
   ```

2. Create the Secret Manager secret for this layer:

   ```bash
   terraform init
   terraform apply -target module.secrets
   ```

3. Set the Hetzner API token in the `hetzner-infra` secret:

   ```bash
   just edit
   ```

Use this JSON shape:

```json
{
  "hcloud_token": "..."
}
```

## Bootstrap Mode

Enable temporary public SSH access for initial setup (nixos-infect runs automatically on first boot):

```bash
TF_VAR_BOOTSTRAP=true terraform apply
```

## ZeroTier Setup

The ZeroTier identity and network membership for this server (`poenttoe`) are managed in the `local-networking` layer. After the server is provisioned and running NixOS, you must manually configure ZeroTier to match the pre-authorized identity.

1.  **Get the Identity Key:**
    Retrieve the generated private key from the `local-networking` layer:

    ```bash
    cd ../local-networking
    terraform output -raw poenttoe_zerotier_private_key
    ```

    *Note: This output is the content of the `identity.secret` file.*

2.  **Get the Network ID:**

    ```bash
    terraform output -raw zerotier_network_id
    ```

3.  **Configure the Server:**
    SSH into `poenttoe` and run the following (replace `<PRIVATE_KEY_CONTENT>` and `<NETWORK_ID>`):

    ```bash
    # Stop the service
    sudo systemctl stop zerotierone

    # Write the identity file (be careful with permissions!)
    sudo echo "<PRIVATE_KEY_CONTENT>" > /var/lib/zerotier-one/identity.secret
    sudo chmod 600 /var/lib/zerotier-one/identity.secret
    sudo chown zerotier-one:zerotier-one /var/lib/zerotier-one/identity.secret

    # Start the service
    sudo systemctl start zerotierone

    # Join the network
    sudo zerotier-cli join <NETWORK_ID>
    ```

4.  **Verify:**
    The server should automatically be authorized and assigned the IP `10.255.255.3` (DNS: `poenttoe.kalski.xyz`).