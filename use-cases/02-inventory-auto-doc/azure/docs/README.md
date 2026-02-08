# Use Case 02 — Azure — Environment Inventory + Auto-Documentation

This runbook generates an Azure subscription inventory (`inventory.json`) and a summary (`SUMMARY.md`) using a local script or GitHub Actions.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_AZURE.md`
- Cleanup guidance: `docs/CLEANUP.md`

## 1. What this stack creates and why

This use case **does not create Azure resources** by default. It:
- Assigns read-only roles to the GitHub OIDC service principal (optional Terraform step).
- Runs a discovery script to capture inventory artifacts.

The output artifacts help with audits, migrations, and onboarding.

## 2. Prerequisites

- **UC05 Azure OIDC bootstrap** completed.
- Azure CLI (`az`) installed and authenticated for local runs.
- `jq` installed.
- The GitHub OIDC service principal must have **Reader** (and optionally **Resource Graph Reader**) on the subscription.

### Optional: Apply discovery access (Terraform)

This stack assigns read-only roles to the GitHub OIDC service principal.

Backend config:
```bash
cp backend/azure-uc02-discovery.hcl.example backend/azure-uc02-discovery.hcl
```

Update `storage_account_name` in the local file. If `use_azuread_auth = true`, ensure the identity has **Storage Blob Data Contributor** on the state storage account.

Apply:
```bash
cd use-cases/02-inventory-auto-doc/azure/terraform/discovery-access
terraform init -reconfigure -backend-config=../../../../../backend/azure-uc02-discovery.hcl
terraform apply -var "principal_object_id=<OIDC_SP_OBJECT_ID>"
```

## 3. Terraform layout

```
use-cases/02-inventory-auto-doc/azure/
├── terraform/
│   └── discovery-access/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── scripts/
└── sample-output/
```

## 4. Run discovery (local)

```bash
cd use-cases/02-inventory-auto-doc/azure/scripts

export AZURE_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export OUT_DIR="out"

./discover.sh
```

Artifacts:
- `out/inventory.json`
- `out/SUMMARY.md`
- `out/artifacts/` (normalized bundle: metadata, summary, scorecard, diagram)

## 5. Run discovery (GitHub Actions)

Workflow: `.github/workflows/uc02-azure-inventory.yml`

```bash
gh workflow run uc02-azure-inventory.yml
```

Download artifact `uc02-azure-inventory`.

## 6. Key variables (Terraform)

| Variable | Default | Purpose |
|----------|---------|---------|
| `principal_object_id` | (required) | Service principal object ID for GitHub OIDC. |
| `enable_resource_graph_role` | `true` | Assign Resource Graph Reader role. |

## 7. Outputs (Terraform)

| Output | Description |
|--------|-------------|
| `role_assignment_ids` | Role assignment IDs created. |

## 8. Post-run checklist

1. Open `SUMMARY.md` and confirm counts look reasonable.
2. Confirm `inventory.json` includes expected resource groups and VNets.

## 9. Notes and troubleshooting

- **Permissions:** The discovery script requires Reader on the subscription. If `az resource list` fails, confirm role assignment.
- **Key Vault list failures:** Some tenants restrict Key Vault list; the script falls back to `[]` if listing fails.
- **Large subscriptions:** `az resource list` can be slow; consider filtering by resource group for very large estates.
- **Resource Graph role lookup:** If Terraform hangs on the Resource Graph Reader role lookup, re-run with `-var "enable_resource_graph_role=false"` and proceed with Reader-only.
- **Azure CLI subscription context:** The script uses `az account set` once and runs subsequent `az` calls without `--subscription`. Ensure your CLI context is set for the target subscription.

## 10. Cleanup

If you applied `discovery-access`, remove the role assignments with Terraform:

```bash
cd use-cases/02-inventory-auto-doc/azure/terraform/discovery-access
terraform destroy -var "principal_object_id=<OIDC_SP_OBJECT_ID>"
```

## 11. Cleanup and repeatability

See `docs/CLEANUP.md` for repeatable run guidance and cleanup steps.

## 12. Validation snapshot

- **Date:** 2026-02-07
- **Result:** Terraform RBAC apply, local discovery, and GitHub Actions run succeeded.
- **Evidence:** Local `out/inventory.json` + `out/SUMMARY.md`, workflow `uc02-azure-inventory` completed.
