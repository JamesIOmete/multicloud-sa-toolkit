# Use Case 03 — Azure — Monitoring Starter Pack

This runbook deploys a baseline monitoring and alerting stack for a token queue workload in Azure.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_AZURE.md`
- Cleanup guidance: `docs/CLEANUP.md`

## 1. What this stack creates and why

This Terraform stack provisions a low-cost queue workload and alerting to demonstrate monitoring patterns.

It creates:
- **Service Bus namespace + queue** (token workload).
- **Azure Monitor Action Group** with email notifications.
- **Azure Monitor Metric Alerts** for:
  - Active messages backlog.
  - Dead-lettered messages.

Every tagged resource includes:
- `toolkit = multicloud-sa-toolkit`
- `use_case = 03-monitoring-starter`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`

Names default to `mcsa-uc03-<env>` unless `var.name_prefix` is set.

## 2. Prerequisites

- **UC05 Azure OIDC bootstrap** completed.
- Permissions to create Service Bus, Azure Monitor alerts, and Action Groups.
- Terraform CLI `>= 1.6`.
- Azure CLI authenticated (`az login`) for local runs.

### Backend configuration

Create a backend config file locally (gitignored):

```bash
cp backend/azure-uc03-monitoring.hcl.example backend/azure-uc03-monitoring.hcl
```

Update `storage_account_name` in the local file. Keep `resource_group_name = "mcsa-tfstate-rg"` and `container_name = "tfstate"` unless your state layout differs.

> If `use_azuread_auth = true`, the identity running Terraform (including GitHub Actions OIDC) must have **Storage Blob Data Contributor** on the state storage account.

## 3. Terraform layout

```
use-cases/03-monitoring-starter/azure/
└── terraform/
    ├── root/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    └── modules/
        ├── token-workload/
        └── alerts/
```

## 4. Quick start (apply baseline)

```bash
cd use-cases/03-monitoring-starter/azure/terraform/root
terraform init -reconfigure -backend-config=../../../../../backend/azure-uc03-monitoring.hcl

export TF_VAR_notification_emails='["sa-team@example.com"]'

terraform plan
terraform apply
```

## 5. Key variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `name_prefix` | `mcsa-uc03-<env>` | Override the default name prefix. |
| `env` | `toolkit-test` | Appears in names/tags. |
| `owner` | `platform-team` | Owner tag for created resources. |
| `location` | `westus2` | Region for Service Bus and alerts. |
| `enable_workload` | `true` | Toggle the Service Bus queue workload. |
| `servicebus_sku` | `Basic` | Service Bus SKU. |
| `enable_alerts` | `true` | Toggle Azure Monitor alerts. |
| `notification_emails` | (required) | Emails for alert notifications. |
| `namespace_resource_id` | (optional) | Existing namespace ID if `enable_workload=false`. |
| `queue_name` | (optional) | Existing queue name if `enable_workload=false`. |
| `backlog_threshold` | `10` | ActiveMessages threshold. |
| `deadletter_threshold` | `1` | DeadletteredMessages threshold. |

## 6. Outputs

| Output | Description |
|--------|-------------|
| `servicebus_namespace_name` | Service Bus namespace name. |
| `servicebus_queue_name` | Service Bus queue name. |
| `action_group_id` | Action group ID. |
| `metric_alert_ids` | Metric alert IDs. |

## 7. Post-apply checklist

1. Confirm the Action Group email subscription in your inbox.
2. Review the queue and alerts in the Azure portal:
   - Service Bus namespace and queue exist.
   - Metric alerts are attached to the queue.

## 8. Notes and troubleshooting

- **Namespace uniqueness:** Service Bus namespace names are globally unique; this stack appends a random suffix to avoid collisions.
- **Service Bus SKU:** `Basic` is lowest cost but has fewer features. Switch to `Standard` if you need more capabilities.
- **Alerting without workload:** Set `enable_workload=false` and provide `namespace_resource_id` and `queue_name` to target an existing queue.
- **Action Group email:** Azure requires you to confirm the Action Group email before alerts are delivered.
- **Metric scope:** Alerts target the namespace metrics with the `EntityName` dimension for the queue.

## 9. Cleanup

```bash
terraform destroy
```

## 10. Cleanup and repeatability

See `docs/CLEANUP.md` for repeatable run guidance and cleanup steps.

## 11. GitHub Actions validation (plan-only)

Workflow: `.github/workflows/uc03-azure-monitoring.yml`

```bash
gh workflow run uc03-azure-monitoring.yml \
  -f storage_account_name=<YOUR_STATE_STORAGE_ACCOUNT> \
  -f notification_emails='["sa-team@example.com"]' \
  -f location="westus2"
```

The workflow:
- Uses `azure/login` with OIDC (no static secrets).
- Runs `az account show` to prove identity.
- Executes `terraform plan` only.

## 12. Validation snapshot

- **Date:** 2026-02-07
- **Result:** Local apply and GitHub Actions plan succeeded.
- **Evidence:** Action Group confirmed, alerts listed via `az monitor metrics alert list`, workflow `uc03-azure-monitoring` completed.
