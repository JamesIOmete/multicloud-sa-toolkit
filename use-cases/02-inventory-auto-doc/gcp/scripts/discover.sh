#!/bin/bash
set -eo pipefail

# This script discovers GCP resources and generates an inventory in JSON format.
# It is designed to be run from a GitHub Actions workflow.

# --- Prerequisites ---
# - gcloud CLI is installed and authenticated.
# - The authenticated principal has the necessary permissions to list resources.

# --- Script Parameters ---
# - PROJECT_ID: The GCP project to scan.
# - REGION: The GCP region to scan.
# - OUTPUT_DIR: The directory to write the output files to.

PROJECT_ID=${1:-$GCP_PROJECT_ID}
REGION=${2:-$GCP_REGION}
OUTPUT_DIR=${3:-.}

if [[ -z "$PROJECT_ID" || -z "$REGION" ]]; then
  echo "Usage: $0 <project-id> <region> [output-dir]"
  echo "Alternatively, set GCP_PROJECT_ID and GCP_REGION environment variables."
  exit 1
fi

echo "---"
echo "Starting GCP discovery for project: $PROJECT_ID"
echo "Region: $REGION"
echo "Output directory: $OUTPUT_DIR"
echo "---"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# --- 1. Metadata and Identity ---
echo "Gathering metadata and identity information..."
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CALLER_IDENTITY=$(gcloud auth print-identity-token)

# --- 2. IAM ---
echo "Gathering IAM information..."
SERVICE_ACCOUNTS=$(gcloud iam service-accounts list --project="$PROJECT_ID" --format=json)

# --- 3. Networking ---
echo "Gathering networking information..."
VPCS=$(gcloud compute networks list --project="$PROJECT_ID" --format=json)
SUBNETS=$(gcloud compute networks subnets list --project="$PROJECT_ID" --format=json)
FIREWALL_RULES=$(gcloud compute firewall-rules list --project="$PROJECT_ID" --format=json)

# --- 4. Compute ---
echo "Gathering compute information..."
INSTANCES=$(gcloud compute instances list --project="$PROJECT_ID" --format=json)

# --- Assemble the JSON output ---
jq -n \
  --arg generated_at "$GENERATED_AT" \
  --arg project_id "$PROJECT_ID" \
  --arg region "$REGION" \
  --argjson service_accounts "$SERVICE_ACCOUNTS" \
  --argjson vpcs "$VPCS" \
  --argjson subnets "$SUBNETS" \
  --argjson firewall_rules "$FIREWALL_RULES" \
  --argjson instances "$INSTANCES" \
  '{
    "meta": {
      "generated_at": $generated_at,
      "project_id": $project_id,
      "region": $region
    },
    "iam": {
      "service_accounts": $service_accounts
    },
    "network": {
      "vpcs": $vpcs,
      "subnets": $subnets,
      "firewall_rules": $firewall_rules
    },
    "compute": {
      "instances": $instances
    }
  }' > "${OUTPUT_DIR}/inventory.json"

echo "Discovery complete. inventory.json created."

# --- Generate SUMMARY.md ---
echo "Generating SUMMARY.md..."

NUM_SERVICE_ACCOUNTS=$(jq '.iam.service_accounts | length' "${OUTPUT_DIR}/inventory.json")
NUM_VPCS=$(jq '.network.vpcs | length' "${OUTPUT_DIR}/inventory.json")
NUM_SUBNETS=$(jq '.network.subnets | length' "${OUTPUT_DIR}/inventory.json")
NUM_FIREWALL_RULES=$(jq '.network.firewall_rules | length' "${OUTPUT_DIR}/inventory.json")
NUM_INSTANCES=$(jq '.compute.instances | length' "${OUTPUT_DIR}/inventory.json")

cat <<EOF > "${OUTPUT_DIR}/SUMMARY.md"
# GCP Inventory Summary

- Generated: $GENERATED_AT
- Project: $PROJECT_ID
- Region: $REGION

## IAM
- Service Accounts: $NUM_SERVICE_ACCOUNTS

## Network
- VPCs: $NUM_VPCS
- Subnets: $NUM_SUBNETS
- Firewall Rules: $NUM_FIREWALL_RULES

## Compute
- Instances: $NUM_INSTANCES

## Artifacts
- inventory.json: full machine-readable inventory
- SUMMARY.md: this summary
EOF

echo "SUMMARY.md created."
echo "---"
echo "Done."
