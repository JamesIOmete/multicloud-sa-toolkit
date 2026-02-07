#!/usr/bin/env bash
set -euo pipefail

SUBSCRIPTION_ID="${1:-${AZURE_SUBSCRIPTION_ID:-}}"
OUT_DIR="${2:-${OUT_DIR:-out}}"

if ! command -v az >/dev/null 2>&1; then
  echo "az CLI not found. Install Azure CLI before running this script." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found. Install jq before running this script." >&2
  exit 1
fi

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
fi

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Usage: $0 <subscription-id> [output-dir]" >&2
  echo "Alternatively, set AZURE_SUBSCRIPTION_ID." >&2
  exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID"

mkdir -p "$OUT_DIR"

ACCOUNT_JSON="$(az account show -o json)"
TENANT_ID="$(echo "$ACCOUNT_JSON" | jq -r '.tenantId')"
SUBSCRIPTION_NAME="$(echo "$ACCOUNT_JSON" | jq -r '.name')"
USER_NAME="$(echo "$ACCOUNT_JSON" | jq -r '.user.name')"

LOCATIONS="$(az account list-locations -o json)"
RESOURCE_GROUPS="$(az group list -o json)"
RESOURCES="$(az resource list -o json)"

VNETS="$(az network vnet list -o json)"
PUBLIC_IPS="$(az network public-ip list -o json)"
NSGS="$(az network nsg list -o json)"

VMS="$(az vm list -o json)"
STORAGE_ACCOUNTS="$(az storage account list -o json)"
KEYVAULTS="$(az keyvault list -o json 2>/dev/null || echo '[]')"

jq -n \
  --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --arg subscription_id "$SUBSCRIPTION_ID" \
  --arg subscription_name "$SUBSCRIPTION_NAME" \
  --arg tenant_id "$TENANT_ID" \
  --arg user_name "$USER_NAME" \
  --argjson account "$ACCOUNT_JSON" \
  --argjson locations "$LOCATIONS" \
  --argjson resource_groups "$RESOURCE_GROUPS" \
  --argjson resources "$RESOURCES" \
  --argjson vnets "$VNETS" \
  --argjson public_ips "$PUBLIC_IPS" \
  --argjson nsgs "$NSGS" \
  --argjson vms "$VMS" \
  --argjson storage_accounts "$STORAGE_ACCOUNTS" \
  --argjson keyvaults "$KEYVAULTS" \
  '{
    meta: {
      generated_at: $generated_at,
      subscription_id: $subscription_id,
      subscription_name: $subscription_name,
      tenant_id: $tenant_id,
      user: $user_name
    },
    identity: {
      account: $account
    },
    locations: $locations,
    resource_groups: $resource_groups,
    resources: $resources,
    network: {
      vnets: $vnets,
      public_ips: $public_ips,
      nsgs: $nsgs
    },
    compute: {
      virtual_machines: $vms
    },
    storage: {
      accounts: $storage_accounts
    },
    security: {
      key_vaults: $keyvaults
    }
  }' > "$OUT_DIR/inventory.json"

RG_COUNT="$(jq '.resource_groups | length' "$OUT_DIR/inventory.json")"
RES_COUNT="$(jq '.resources | length' "$OUT_DIR/inventory.json")"
VNET_COUNT="$(jq '.network.vnets | length' "$OUT_DIR/inventory.json")"
PIP_COUNT="$(jq '.network.public_ips | length' "$OUT_DIR/inventory.json")"
NSG_COUNT="$(jq '.network.nsgs | length' "$OUT_DIR/inventory.json")"
VM_COUNT="$(jq '.compute.virtual_machines | length' "$OUT_DIR/inventory.json")"
SA_COUNT="$(jq '.storage.accounts | length' "$OUT_DIR/inventory.json")"
KV_COUNT="$(jq '.security.key_vaults | length' "$OUT_DIR/inventory.json")"

cat > "$OUT_DIR/SUMMARY.md" <<EOF2
# Azure Inventory Summary (Use Case 02)

- Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)
- Tenant: $TENANT_ID
- Caller: $USER_NAME

## Resource Overview
- Resource Groups: **$RG_COUNT**
- Resources: **$RES_COUNT**

## Network
- VNets: **$VNET_COUNT**
- Public IPs: **$PIP_COUNT**
- Network Security Groups: **$NSG_COUNT**

## Compute
- Virtual Machines: **$VM_COUNT**

## Storage & Security
- Storage Accounts: **$SA_COUNT**
- Key Vaults: **$KV_COUNT**

## Artifacts
- inventory.json: full machine-readable inventory
- SUMMARY.md: this summary
EOF2

echo "Wrote: $OUT_DIR/inventory.json"
echo "Wrote: $OUT_DIR/SUMMARY.md"
