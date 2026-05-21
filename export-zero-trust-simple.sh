#!/usr/bin/env bash

set -euo pipefail

OUTPUT_FILE="${OUTPUT_FILE:-zero-trust.tf}"
LOG_FILE="${LOG_FILE:-zero-trust-generate.log}"
ACCOUNT_ID="${ACCOUNT_ID:-${1:-}}"
EMAIL="${CLOUDFLARE_EMAIL:-}"
TOKEN="${CLOUDFLARE_API_TOKEN:-}"
API_KEY="${CLOUDFLARE_API_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_WORKDIR="${TF_WORKDIR:-$SCRIPT_DIR/.cf-terraforming-tmp}"
MIN_CF_TERRAFORMING_VERSION="0.25.0"

if [[ -z "$ACCOUNT_ID" ]]; then
  printf 'usage: ACCOUNT_ID=<account_id> %s\n' "$(basename "$0")" >&2
  printf '   or: %s <account_id>\n' "$(basename "$0")" >&2
  exit 1
fi

if [[ -z "$TOKEN" && ( -z "$EMAIL" || -z "$API_KEY" ) ]]; then
  printf 'set CLOUDFLARE_API_TOKEN or CLOUDFLARE_EMAIL + CLOUDFLARE_API_KEY\n' >&2
  exit 1
fi

if ! command -v cf-terraforming >/dev/null 2>&1; then
  printf 'cf-terraforming binary not found in PATH\n' >&2
  exit 1
fi

CF_TERRAFORMING_VERSION_RAW="$(cf-terraforming version 2>/dev/null || true)"
CF_TERRAFORMING_VERSION="$(printf '%s' "$CF_TERRAFORMING_VERSION_RAW" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || true)"

if [[ -z "$CF_TERRAFORMING_VERSION" ]]; then
  printf 'unable to determine cf-terraforming version\n' >&2
  exit 1
fi

if [[ "$(printf '%s\n%s\n' "$MIN_CF_TERRAFORMING_VERSION" "$CF_TERRAFORMING_VERSION" | sort -V | head -n1)" != "$MIN_CF_TERRAFORMING_VERSION" ]]; then
  printf 'cf-terraforming %s or newer is required, found %s\n' "$MIN_CF_TERRAFORMING_VERSION" "$CF_TERRAFORMING_VERSION" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  printf 'terraform binary not found in PATH\n' >&2
  exit 1
fi

mkdir -p "$TF_WORKDIR"

if [[ ! -f "$TF_WORKDIR/main.tf" ]]; then
  cat > "$TF_WORKDIR/main.tf" <<'EOF'
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "cloudflare" {}
EOF
fi

if [[ ! -d "$TF_WORKDIR/.terraform/providers" ]]; then
  printf 'Initializing Terraform working directory...\n'
  terraform -chdir="$TF_WORKDIR" init >/dev/null
fi

RESOURCE_TYPES=(
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
)

# These require --resource-id and are intentionally omitted from the bulk run:
# - cloudflare_zero_trust_dlp_custom_profile
# - cloudflare_zero_trust_dlp_predefined_profile
# - cloudflare_zero_trust_tunnel_cloudflared_config

: > "$OUTPUT_FILE"
: > "$LOG_FILE"

successes=0
skips=0
failures=0

for resource_type in "${RESOURCE_TYPES[@]}"; do
  resource_output="$(mktemp)"
  resource_log="$(mktemp)"

  printf 'Generating %s\n' "$resource_type" | tee -a "$LOG_FILE"

  if [[ -n "$TOKEN" ]]; then
    auth_args=(--token "$TOKEN")
  else
    auth_args=(--email "$EMAIL" --key "$API_KEY")
  fi

  if cf-terraforming generate \
    "${auth_args[@]}" \
    --account "$ACCOUNT_ID" \
    --terraform-binary-path "$(command -v terraform)" \
    --terraform-install-path "$TF_WORKDIR" \
    --resource-type "$resource_type" \
    > "$resource_output" 2> "$resource_log"; then
    cat "$resource_log" >> "$LOG_FILE"
    printf '\n' >> "$LOG_FILE"

    if grep -q 'no resources of type' "$resource_log"; then
      printf 'Skipping %s: no resources found\n' "$resource_type" | tee -a "$LOG_FILE"
      skips=$((skips + 1))
    elif grep -q 'is not yet supported for automatic generation' "$resource_output"; then
      printf 'Skipping %s: resource type unsupported by installed cf-terraforming\n' "$resource_type" | tee -a "$LOG_FILE"
      failures=$((failures + 1))
    elif [[ ! -s "$resource_output" ]]; then
      printf 'Skipping %s: no output generated\n' "$resource_type" | tee -a "$LOG_FILE"
      skips=$((skips + 1))
    else
      cat "$resource_output" >> "$OUTPUT_FILE"
      printf '\n' >> "$OUTPUT_FILE"
      successes=$((successes + 1))
    fi
  else
    cat "$resource_log" >> "$LOG_FILE"
    printf '\n' >> "$LOG_FILE"
    if grep -q 'no resources of type' "$resource_log"; then
      printf 'Skipping %s: no resources found\n' "$resource_type" | tee -a "$LOG_FILE"
      skips=$((skips + 1))
    else
      printf 'Skipping %s: generation failed\n' "$resource_type" | tee -a "$LOG_FILE"
      failures=$((failures + 1))
    fi
  fi

  rm -f "$resource_output" "$resource_log"
done

printf 'Finished: %d succeeded, %d empty, %d failed\n' "$successes" "$skips" "$failures" | tee -a "$LOG_FILE"

if [[ -s "$OUTPUT_FILE" ]]; then
  printf 'Resource summary:\n' | tee -a "$LOG_FILE"
  awk '/^resource "/ {gsub(/"/, "", $2); counts[$2]++} END {for (k in counts) print k, counts[k]}' "$OUTPUT_FILE" \
    | sort \
    | tee -a "$LOG_FILE"
fi
