# Zero Trust Export Script

Exports common Cloudflare Zero Trust Terraform resources for a single account into one file.

## Requirements

- `terraform` installed and available in `PATH`
- `cf-terraforming` `0.25.0` or newer installed and available in `PATH`
- a Cloudflare account ID

## Setup

Make the script executable:

```bash
chmod +x ./export-zero-trust-simple.sh
```

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
 
  ## Resources
  cloudflare_zero_trust_access_application
  cloudflare_zero_trust_access_custom_page
  cloudflare_zero_trust_access_group
  cloudflare_zero_trust_access_identity_provider
  cloudflare_zero_trust_access_infrastructure_target
  cloudflare_zero_trust_access_key_configuration
  cloudflare_zero_trust_access_mtls_certificate
  cloudflare_zero_trust_access_mtls_hostname_settings
  cloudflare_zero_trust_access_policy
  cloudflare_zero_trust_access_service_token
  cloudflare_zero_trust_access_short_lived_certificate
  cloudflare_zero_trust_access_tag
  cloudflare_zero_trust_device_custom_profile
  cloudflare_zero_trust_device_default_profile
  cloudflare_zero_trust_device_default_profile_local_domain_fallback
  cloudflare_zero_trust_device_managed_networks
  cloudflare_zero_trust_device_posture_integration
  cloudflare_zero_trust_device_posture_rule
  cloudflare_zero_trust_dex_test
  cloudflare_zero_trust_dlp_dataset
  cloudflare_zero_trust_dns_location
  cloudflare_zero_trust_gateway_certificate
  cloudflare_zero_trust_gateway_policy
  cloudflare_zero_trust_gateway_proxy_endpoint
  cloudflare_zero_trust_gateway_settings
  cloudflare_zero_trust_list
  cloudflare_zero_trust_organization
  cloudflare_zero_trust_risk_behavior
  cloudflare_zero_trust_risk_scoring_integration
  cloudflare_zero_trust_tunnel_cloudflared
  cloudflare_zero_trust_tunnel_cloudflared_route
  cloudflare_zero_trust_tunnel_cloudflared_virtual_network
