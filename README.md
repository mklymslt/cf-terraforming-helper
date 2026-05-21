# Zero Trust Export Script

Exports common Cloudflare Zero Trust Terraform resources for a single account into one file.

## Requirements

- `terraform` installed and available in `PATH`
- `cf-terraforming` `0.25.0` or newer installed and available in `PATH`
- a Cloudflare account ID

## Authentication

Use one of these auth methods.

Scoped API token:

```bash
export CLOUDFLARE_API_TOKEN="<your_api_token>"
```

Global API key:

```bash
export CLOUDFLARE_EMAIL="<your_email>"
export CLOUDFLARE_API_KEY="<your_global_api_key>"
```

Difference:

- `CLOUDFLARE_API_TOKEN` is a scoped API token.
- `CLOUDFLARE_EMAIL` + `CLOUDFLARE_API_KEY` is the older global API key auth method.

## Usage

Run the script with your Cloudflare account ID:

```bash
./export-zero-trust-simple.sh "<account_id>"
```

## Output

The script writes these files in the directory where you run it:

```text
zero-trust.tf
zero-trust-generate.log
```

It also prints a summary count of each exported Terraform resource type.

If you see output like `"..." is not yet supported for automatic generation`, your `cf-terraforming` version is too old.

## Notes

- The script creates and initializes its own temporary Terraform working directory automatically.
- It skips empty resource types and continues.
- It does not include resource types that require explicit `--resource-id` values:
  - `cloudflare_zero_trust_dlp_custom_profile`
  - `cloudflare_zero_trust_dlp_predefined_profile`
  - `cloudflare_zero_trust_tunnel_cloudflared_config`
