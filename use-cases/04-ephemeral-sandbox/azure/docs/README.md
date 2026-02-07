# Use Case 04 — Azure — Ephemeral Sandbox Factory

This runbook provisions a short-lived, low-cost sandbox environment in Azure.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_AZURE.md`
- Cleanup guidance: `docs/CLEANUP.md`

## 1. What this stack creates and why

This Terraform stack provisions an ephemeral sandbox environment for development, demos, and testing. Resources are tagged with a unique `sandbox_id` for easy cleanup.

It creates:
- **Resource Group** for the sandbox.
- **VNet + Subnet** for isolation.
- **Azure Container Instance** running a lightweight hello-world container.
- **Subscription Budget** to cap costs.

Every tagged resource includes:
- `toolkit = multicloud-sa-toolkit`
- `use_case = 04-ephemeral-sandbox`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`
- `sandbox_id = <var.sandbox_id>`

Names default to `mcsa-uc04-<env>-<sandbox_id>` unless `var.name_prefix` is set.

## 2. Prerequisites

- **UC05 Azure OIDC bootstrap** completed.
- Permissions to create Resource Groups, Service Bus, Container Instances, and Budgets.
- Terraform CLI `>= 1.6`.
- Azure CLI authenticated (`az login`) for local runs.

### Backend configuration

Create a backend config file locally (gitignored):

```bash
cp backend/azure-uc04-ephemeral-sandbox.hcl.example backend/azure-uc04-ephemeral-sandbox.hcl
```

Update `storage_account_name` in the local file. Keep `resource_group_name = "mcsa-tfstate-rg"` and `container_name = "tfstate"` unless your state layout differs.

> If `use_azuread_auth = true`, the identity running Terraform (including GitHub Actions OIDC) must have **Storage Blob Data Contributor** on the state storage account.

## 3. Terraform layout

```
use-cases/04-ephemeral-sandbox/azure/
└── terraform/
    ├── root/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    └── modules/
        ├── network/
        ├── workload/
        └── cost-controls/
```

## 4. Quick start (apply sandbox)

```bash
cd use-cases/04-ephemeral-sandbox/azure/terraform/root
terraform init -reconfigure -backend-config=../../../../../backend/azure-uc04-ephemeral-sandbox.hcl

export TF_VAR_sandbox_id="sbx01"
export TF_VAR_notification_emails='["sa-team@example.com"]'

terraform plan
terraform apply
```

## 5. Key variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `sandbox_id` | (required) | Unique sandbox identifier (used in tags/names). |
| `name_prefix` | `mcsa-uc04-<env>` | Override the default name prefix. |
| `env` | `toolkit-test` | Appears in names/tags. |
| `owner` | `platform-team` | Owner tag for created resources. |
| `location` | `westus2` | Region for resources. |
| `enable_network` | `true` | Toggle VNet + subnet creation. |
| `enable_workload` | `true` | Toggle container workload creation. |
| `container_image` | `mcr.microsoft.com/azuredocs/aci-helloworld` | Container image. |
| `container_cpu` | `1` | CPU cores for container. |
| `container_memory` | `1.5` | Memory (GB) for container. |
| `enable_cost_controls` | `true` | Toggle subscription budget. |
| `monthly_budget_amount` | `25` | Monthly budget in USD. |
| `budget_thresholds` | `[80,100]` | Budget alert thresholds. |
| `notification_emails` | (required) | Emails for budget alerts. |
| `budget_start_date` | (current month) | Budget start date (RFC3339). |
| `vnet_cidr` | `10.60.0.0/16` | VNet CIDR. |
| `subnet_cidr` | `10.60.1.0/24` | Subnet CIDR. |

## 6. Outputs

| Output | Description |
|--------|-------------|
| `resource_group_name` | Resource group name. |
| `vnet_name` | VNet name. |
| `subnet_name` | Subnet name. |
| `container_fqdn` | Container FQDN for the sandbox app. |
| `budget_name` | Budget name. |

## 7. Post-apply checklist

1. Confirm the container FQDN responds with the hello-world page.
2. Verify the budget exists in the Azure portal.
3. Confirm tags include `sandbox_id` for cleanup filtering.

## 8. Notes and troubleshooting

- **Container DNS:** The ACI DNS label must be globally unique per region; this stack appends a random suffix.
- **Budget start date:** Azure budgets reject a start date prior to the current month. Leave `budget_start_date` empty to use the current month default.
- **Sandbox naming:** Updating `sandbox_id` or `name_prefix` forces replacement of most resources.

## 9. Cleanup

```bash
terraform destroy
```

## 10. Cleanup and repeatability

See `docs/CLEANUP.md` for repeatable run guidance and cleanup steps.

## 11. GitHub Actions validation (plan-only)

Workflow: `.github/workflows/uc04-azure-ephemeral-sandbox.yml`

```bash
gh workflow run uc04-azure-ephemeral-sandbox.yml \
  -f storage_account_name=<YOUR_STATE_STORAGE_ACCOUNT> \
  -f sandbox_id=sbx01 \
  -f notification_emails='["sa-team@example.com"]' \
  -f location="westus2"
```

The workflow:
- Uses `azure/login` with OIDC (no static secrets).
- Runs `az account show` to prove identity.
- Executes `terraform plan` only.

## 12. Validation snapshot

- **Date:** 2026-02-07
- **Result:** Not yet run in this repo; expected to plan successfully once backend config and notification emails are provided.
- **Evidence:** N/A
