#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-west-2}"
OUT_DIR="${OUT_DIR:-out}"
mkdir -p "$OUT_DIR"

# Helpers
j() { jq -c '.'; }

ACCOUNT_JSON="$(aws sts get-caller-identity --output json)"
ACCOUNT_ID="$(echo "$ACCOUNT_JSON" | jq -r .Account)"

ALIAS="$(aws iam list-account-aliases --output json | jq -r '.AccountAliases[0] // ""')"

ROLE_NAME="${TARGET_ROLE_NAME:-github-terraform-oidc}"
ROLE_JSON="$(aws iam get-role --role-name "$ROLE_NAME" --output json 2>/dev/null || echo '{}')"
ATTACHED_POLICIES_JSON="$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --output json 2>/dev/null || echo '{"AttachedPolicies":[]}')"

VPCS="$(aws ec2 describe-vpcs --region "$REGION" --output json)"
SUBNETS="$(aws ec2 describe-subnets --region "$REGION" --output json)"
ROUTES="$(aws ec2 describe-route-tables --region "$REGION" --output json)"
IGWS="$(aws ec2 describe-internet-gateways --region "$REGION" --output json)"
NATS="$(aws ec2 describe-nat-gateways --region "$REGION" --output json)"
SGS="$(aws ec2 describe-security-groups --region "$REGION" --output json)"
EIPS="$(aws ec2 describe-addresses --region "$REGION" --output json)"
PEERING="$(aws ec2 describe-vpc-peering-connections --region "$REGION" --output json)"
TGWS="$(aws ec2 describe-transit-gateways --region "$REGION" --output json)"
TGW_ATTACH="$(aws ec2 describe-transit-gateway-attachments --region "$REGION" --output json)"
VPCE="$(aws ec2 describe-vpc-endpoints --region "$REGION" --output json)"

INSTANCES="$(aws ec2 describe-instances --region "$REGION" --output json)"
ASGS="$(aws autoscaling describe-auto-scaling-groups --region "$REGION" --output json 2>/dev/null || echo '{"AutoScalingGroups":[]}')"
ELBv2="$(aws elbv2 describe-load-balancers --region "$REGION" --output json 2>/dev/null || echo '{"LoadBalancers":[]}')"

INV_JSON="$OUT_DIR/inventory.json"
SUM_MD="$OUT_DIR/SUMMARY.md"

jq -n \
  --arg region "$REGION" \
  --arg account_id "$ACCOUNT_ID" \
  --arg account_alias "$ALIAS" \
  --arg role_name "$ROLE_NAME" \
  --argjson caller "$ACCOUNT_JSON" \
  --argjson role "$ROLE_JSON" \
  --argjson role_attached "$ATTACHED_POLICIES_JSON" \
  --argjson vpcs "$VPCS" \
  --argjson subnets "$SUBNETS" \
  --argjson route_tables "$ROUTES" \
  --argjson igws "$IGWS" \
  --argjson nat_gateways "$NATS" \
  --argjson security_groups "$SGS" \
  --argjson eips "$EIPS" \
  --argjson vpc_peering "$PEERING" \
  --argjson transit_gateways "$TGWS" \
  --argjson transit_gateway_attachments "$TGW_ATTACH" \
  --argjson vpc_endpoints "$VPCE" \
  --argjson instances "$INSTANCES" \
  --argjson asgs "$ASGS" \
  --argjson elbv2 "$ELBv2" \
  '{
    meta: {
      generated_at: (now | todateiso8601),
      region: $region
    },
    identity: {
      account_id: $account_id,
      account_alias: $account_alias,
      caller: $caller
    },
    iam: {
      discovery_role_name: $role_name,
      role: $role,
      attached_policies: $role_attached.AttachedPolicies
    },
    network: {
      vpcs: $vpcs.Vpcs,
      subnets: $subnets.Subnets,
      route_tables: $route_tables.RouteTables,
      internet_gateways: $igws.InternetGateways,
      nat_gateways: $nat_gateways.NatGateways,
      security_groups: $security_groups.SecurityGroups,
      elastic_ips: $eips.Addresses,
      vpc_peering_connections: $vpc_peering.VpcPeeringConnections,
      transit_gateways: $transit_gateways.TransitGateways,
      transit_gateway_attachments: $transit_gateway_attachments.TransitGatewayAttachments,
      vpc_endpoints: $vpc_endpoints.VpcEndpoints
    },
    compute: {
      ec2_instances: ($instances.Reservations | map(.Instances) | add // []),
      autoscaling_groups: $asgs.AutoScalingGroups,
      load_balancers_v2: $elbv2.LoadBalancers
    }
  }' > "$INV_JSON"

VPC_COUNT="$(jq '.network.vpcs | length' "$INV_JSON")"
SUBNET_COUNT="$(jq '.network.subnets | length' "$INV_JSON")"
SG_COUNT="$(jq '.network.security_groups | length' "$INV_JSON")"
EC2_COUNT="$(jq '.compute.ec2_instances | length' "$INV_JSON")"
LB_COUNT="$(jq '.compute.load_balancers_v2 | length' "$INV_JSON")"

cat > "$SUM_MD" <<EOF2
# AWS Inventory Summary (Use Case 02 — MVP)

- Generated: $(date -Is)
- Account: \`$ACCOUNT_ID\`${ALIAS:+ (alias: \`$ALIAS\`)}
- Region: \`$REGION\`
- Discovery Role: \`$ROLE_NAME\`

## Network
- VPCs: **$VPC_COUNT**
- Subnets: **$SUBNET_COUNT**
- Security Groups: **$SG_COUNT**

## Compute
- EC2 instances: **$EC2_COUNT**
- Load balancers (v2): **$LB_COUNT**

## Artifacts
- \`inventory.json\`: full machine-readable inventory
- \`SUMMARY.md\`: this summary
EOF2

echo "Wrote: $INV_JSON"
echo "Wrote: $SUM_MD"
