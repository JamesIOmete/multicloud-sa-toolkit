# Use Case 01 — Azure — Landing Zone Lite Baseline

This runbook deploys a minimum governance baseline in a single Azure subscription: guardrails, centralized activity logging, and cost controls.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_AZURE.md`
- Cleanup guidance: `docs/CLEANUP.md`

## Scope decision (required)

**Scope:** Subscription-only. Policies and logging are assigned to the target subscription (no Management Group scope).

Why: subscription scope is the lowest-friction option, keeps blast radius limited, and aligns with the UC01 “lite” intent. If you need Management Group scope later, extend this stack after UC01 proves out the baseline.

## 1. What this stack creates and why

This Terraform stack establishes a foundational governance baseline within a single Azure subscription.

It creates:
- **Logging baseline** (module `logging`)
  - Resource group for logging assets.
  - Storage account for Activity Log archival.
  - Optional Log Analytics workspace.
  - Subscription Activity Log diagnostic setting to export logs.
- **Guardrails** (module `guardrails`)
  - Policy assignment to restrict allowed locations.
  - Policy assignment to deny Public IP creation.
- **Cost controls** (module `cost-controls`)
  - Monthly subscription budget with threshold notifications.

Every tagged resource includes:
- `toolkit = multicloud-sa-toolkit`
- `use_case = 01-landing-zone-lite`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`

Names default to `mcsa-uc01-<env>` unless `var.name_prefix` is set.

## 2. Prerequisites

- **UC05 Azure OIDC bootstrap** completed, so GitHub Actions can authenticate without secrets.
- Permissions to create policy assignments, budgets, storage accounts, and diagnostic settings in the subscription.
- Terraform CLI `>= 1.6`.
- Azure CLI authenticated (`az login`) for local runs.

### Backend configuration

Create a backend config file locally (gitignored):

```bash
cp backend/azure-uc01-landing-zone.hcl.example backend/azure-uc01-landing-zone.hcl
```

Update `storage_account_name` in the local file. Keep `resource_group_name = "mcsa-tfstate-rg"` and `container_name = "tfstate"` unless your state layout differs.

> If `use_azuread_auth = true`, the identity running Terraform (including GitHub Actions OIDC) must have **Storage Blob Data Contributor** on the state storage account.

## 3. Terraform layout

```
use-cases/01-landing-zone-lite/azure/
└── terraform/
    ├── root/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    └── modules/
        ├── logging/
        ├── guardrails/
        └── cost-controls/
```

## 4. Quick start (apply baseline)

```bash
cd use-cases/01-landing-zone-lite/azure/terraform/root
terraform init -reconfigure -backend-config=../../../../../backend/azure-uc01-landing-zone.hcl

export TF_VAR_cost_notification_emails='["sa-team@example.com"]'
export TF_VAR_allowed_locations='["eastus"]'

terraform plan
terraform apply
```

## 5. Key variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `name_prefix` | `mcsa-uc01-<env>` | Override the default name prefix. |
| `env` | `toolkit-test` | Appears in names/tags (mcsa-uc01-<env>). |
| `owner` | `platform-team` | Owner tag for created resources. |
| `location` | `eastus` | Region for logging resources. Must be included in `allowed_locations`. |
| `allowed_locations` | `["eastus"]` | Regions permitted by policy. Must include `location`. |
| `enable_logging` | `true` | Toggle the logging module. |
| `enable_storage_archive` | `true` | Send Activity Logs to Storage. |
| `enable_log_analytics` | `false` | Send Activity Logs to Log Analytics. |
| `log_storage_account_name` | (generated) | Override the storage account name. |
| `log_analytics_retention_days` | `30` | Log Analytics retention in days. |
| `storage_retention_days` | `365` | Storage retention in days. |
| `enable_guardrails` | `true` | Toggle the guardrails module. |
| `enable_cost_controls` | `true` | Toggle the cost controls module. |
| `monthly_budget_amount` | `100` | Monthly budget amount in USD. |
| `budget_thresholds` | `[50,80,100]` | Percentage thresholds for budget alerts. |
| `cost_notification_emails` | (required) | Emails for budget notifications. |
| `budget_start_date` | (current month) | Budget start date (RFC3339). Leave empty to use current month. |

## 6. Outputs

| Output | Description |
|--------|-------------|
| `log_storage_account_name` | Storage account name for log archival. |
| `log_analytics_workspace_id` | Log Analytics workspace ID (if enabled). |
| `activity_log_diagnostic_setting_id` | Subscription Activity Log diagnostic setting ID. |
| `policy_assignment_ids` | Policy assignment IDs for guardrails. |
| `budget_name` | Subscription budget name. |

## 7. Post-apply checklist

1. Confirm the Activity Log diagnostic setting is present and exporting logs.
2. Validate policy assignments in Azure Policy -> Assignments.
3. Verify the subscription budget and notification recipients.

## 8. Notes and troubleshooting

- **Name changes cause replacement:** Updating `name_prefix` forces recreation of resources like storage accounts and workspaces.
- **Storage account naming:** If you override `log_storage_account_name`, it must be globally unique and 3–24 lowercase alphanumeric characters.
- **Log Analytics costs:** Leave `enable_log_analytics = false` if you want the lowest-cost baseline.
- **Policy enforcement:** These assignments are enforcing by default. Use Azure Policy exemptions if you need temporary audit-only behavior.
- **Allowed locations must include the logging region:** Ensure `allowed_locations` includes `location`, or the logging storage account creation will be blocked by policy.
- **Budget start date:** Azure budgets reject a start date prior to the current month. Leave `budget_start_date` empty to use the current month default.

## 9. Cleanup

```bash
terraform destroy
```

If Activity Log data remains in the storage account after destroy, delete the account manually once logs are no longer required.

## 10. Cleanup and repeatability

See `docs/CLEANUP.md` for repeatable run guidance and cleanup steps.

## 11. GitHub Actions validation (plan-only)

Workflow: `.github/workflows/uc01-azure-landing-zone.yml`

Trigger via CLI:

```bash
gh workflow run uc01-azure-landing-zone.yml \
  -f storage_account_name=<YOUR_STATE_STORAGE_ACCOUNT> \
  -f notification_emails='["sa-team@example.com"]'
```

The workflow:
- Uses `azure/login` with OIDC (no static secrets).
- Runs `az account show` to prove identity.
- Executes `terraform plan` only.

Workflow notes:
- Inputs for `notification_emails` and `allowed_locations` must be JSON lists (example: `["user@example.com"]`).
- `ARM_SUBSCRIPTION_ID` is set from `AZURE_SUBSCRIPTION_ID` in the workflow to satisfy the AzureRM provider.

## 12. Validation snapshot

- **Date:** 2026-01-21
- **Result:** Not yet run in this repo; expected to plan successfully once backend config and notification emails are provided.
- **Evidence:** N/A
