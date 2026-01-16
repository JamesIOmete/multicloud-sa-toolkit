# UC01 AWS - Landing Zone Lite Baseline (MVP)

Establish guardrails, centralized logging, and cost controls in a single AWS account before workloads land there.

---

## What UC01 creates
- **Logging baseline** (module `logging`)
  - Multi-region CloudTrail with KMS-encrypted S3 delivery and optional CloudWatch Logs stream.
  - AWS Config recorder and delivery channel (enabled by default).
  - Log bucket with versioning, lifecycle retention, and Block Public Access.
- **Guardrails** (module `guardrails`)
  - EventBridge rules that alert when CloudTrail or Config are stopped/modified.
  - SNS topic + email notifications for guardrail alerts.
  - Optional Organizations SCP pack (disabled by default) to deny disabling CloudTrail/Config.
- **Cost controls** (module `cost-controls`)
  - Monthly AWS Budget with % thresholds (defaults 50/80/100).
  - Cost Explorer anomaly detection monitor + subscription.
  - SNS topic + email notifications for cost events.

Every resource is tagged with:
- `toolkit = multicloud-sa-toolkit`
- `use_case = 01-landing-zone-lite`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`

Names follow `mcsa-uc01-<env>` unless you override `var.name_prefix`.

---

## When to run it
- **Before** onboarding a new AWS account so all future automation inherits baseline guardrails.
- Whenever the baseline needs an update (new alert recipients, retention changes, optional SCP rollout).
- Not intended for continuous re-application; treat it like a configuration baseline you apply as needed.

---

## Prerequisites
1. **Identity bootstrap (UC05)** complete so GitHub Actions OIDC role can assume required permissions.
2. **AWS account access** with rights to create IAM roles, SNS, Budgets, Cost Explorer, Config, and CloudTrail.
3. **Backend configuration** file (example: `backend/aws-uc01-landing-zone.hcl.example`) containing your S3 state bucket/key. Copy it locally to `backend/aws-uc01-landing-zone.hcl` (ignored by git).
4. Terraform CLI `>= 1.6` and AWS provider `>= 5.0`.

Optional (for SCP pack): the account must be part of an AWS Organization and you know the OU/account IDs to target.

---

## Terraform layout
```
use-cases/01-landing-zone-lite/aws/terraform/
  root/                # composition layer (enable/disable modules)
  modules/
    logging/           # CloudTrail, Config, KMS, log bucket
    guardrails/        # EventBridge + SNS + optional SCP
    cost-controls/     # Budgets + anomaly detection
```

---

## Quick start (apply baseline)

```bash
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true

cd use-cases/01-landing-zone-lite/aws/terraform/root
terraform init -reconfigure -backend-config=../../../../../backend/aws-uc01-landing-zone.hcl
terraform plan -var "guardrail_notification_emails=[\"sa-team@example.com\"]" \
               -var "cost_notification_emails=[\"sa-team@example.com\"]"
terraform apply
```

> For CI proof runs, wire this stack into a GitHub Actions workflow using the UC05 OIDC role.

---

## Key variables (root module)

| Variable | Default | Purpose |
|----------|---------|---------|
| `env` | `toolkit-test` | Appears in names/tags (mcsa-uc01-<env>). |
| `owner` | `platform-team` | Owner tag for created resources. |
| `enable_logging` | `true` | Toggle the logging module. |
| `enable_guardrails` | `true` | Toggle the guardrails module. |
| `enable_cost_controls` | `true` | Toggle the cost controls module. |
| `guardrail_notification_emails` | `[]` | Email list for guardrail SNS topic (required when guardrails enabled). |
| `cost_notification_emails` | `[]` | Email list for cost SNS topic (required when cost controls enabled). |
| `monthly_budget_amount` | `100` | Monthly USD budget threshold. |
| `budget_thresholds` | `[50,80,100]` | Forecast percentage alerts sent via SNS. |
| `anomaly_threshold` | `50` | Cost Explorer anomaly dollar threshold. |
| `enable_scp_pack` | `false` | Enable optional Organizations SCP; requires Org membership. |

Each submodule exposes additional knobs (retention, CloudWatch streaming, Config coverage). See `modules/<name>/variables.tf` for the full list.

---

## Outputs
- `log_bucket_name` — S3 bucket capturing CloudTrail/Config logs.
- `guardrail_alert_topic_arn` — SNS topic for guardrail alerts.
- `cost_alert_topic_arn` — SNS topic for budget/anomaly alerts.

---

## Post-apply checklist
- Confirm SNS email subscriptions for guardrail and cost alert topics.
- Verify CloudTrail is enabled and delivering to the log bucket.
- Verify AWS Config recorder + delivery channel are enabled.

---

## Notes and troubleshooting
- **SNS subscriptions:** `terraform apply` creates email subscriptions; you must confirm them in your inbox.
- **Budget names:** AWS Budgets names are account-unique. If you re-run and see a duplicate error, import the budget or change the name prefix.
- **Anomaly alerts:** DAILY/WEEKLY frequencies require EMAIL subscribers. Use `anomaly_frequency = "IMMEDIATE"` if you want SNS-based anomaly alerts.
- **Config delivery errors:** If Config cannot write to S3, the log bucket policy or KMS permissions are usually the cause.
- **CloudTrail log group errors:** CloudTrail requires a log group ARN with a `:*` suffix and KMS key permissions for `logs.<region>.amazonaws.com`.

---

## Cleanup
All resources share the `mcsa-uc01-<env>` prefix and toolkit tags. To remove the baseline:

```bash
terraform destroy
```

If you enabled the SCP pack, detach the policy (or destroy via Terraform) before deleting the account from the Organization.

---

## Next steps
- Integrate these alerts with Slack/PagerDuty by replacing or extending the SNS subscriptions.
- Extend cost controls with project/account filters once you have tagging standards.
- Pair UC01 with UC02 (inventory) to capture a “post-baseline” snapshot for auditing.
