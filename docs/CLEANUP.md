# Cleanup and Repeatability

This guide explains how to safely repeat runs with different variables, and how to clean up artifacts created by each use case.

## General guidance
- Prefer `terraform apply` with updated variables for in-place changes.
- When changing naming/prefix variables, expect replacements and manual cleanup.
- S3 log buckets are versioned and not `force_destroy`; empty them before `terraform destroy`.
- KMS keys have deletion windows; full removal is delayed by AWS.
- If an apply fails, re-run `terraform apply` after fixing the error; Terraform will converge.

---

## Toolkit-wide cleanup (AWS)

This is the "reset to before the toolkit ran" routine. It assumes use cases were applied in dependency order and can be torn down in reverse.

### Recommended order (full teardown)
1) UC04 ephemeral sandbox
2) UC03 monitoring starter
3) UC02 inventory + auto-doc discovery access
4) UC01 landing zone lite baseline
5) UC05 identity bootstrap (only after you no longer need GitHub Actions OIDC access)

### Global resource sweep (prefix-based)
Use Resource Explorer or tagging to confirm the account is clean of `mcsa-` resources.
- Resource Explorer search: `mcsa-`
- Tag filters (best effort): `toolkit=multicloud-sa-toolkit`, `use_case=...`, `env=...`
- Resource Explorer results can lag; wait a few minutes and recheck if a just-deleted resource still appears.

#### Helpful commands (AWS CLI)
Resource Explorer (fast cross-service search; requires a default view):
```bash
aws resource-explorer-2 search --query-string "mcsa-" --output table
```

Tagging API (only tagged resources, slower but no Resource Explorer setup):
```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=toolkit,Values=multicloud-sa-toolkit \
  --output table
```

If you want a raw list of ARNs for audit or scripting:
```bash
aws resource-explorer-2 search --query-string "mcsa-" \
  --query "Resources[].Arn" --output text
```

### Dependency-aware deletion notes
- ECS/ALB: delete ECS services before clusters; delete ALB listeners/target groups before the load balancer.
- VPC: delete NAT gateways and EIPs before subnets, then route tables, then IGW, then VPC.
- CloudTrail/Config: stop logging/recording before destroy if they are enabled.
- S3 log buckets: empty (including versions) before destroy.
- KMS keys: deletion is scheduled and will linger until the window completes.
- SNS subscriptions: may require manual unsubscribe if created outside Terraform.

---

## UC01 AWS - Landing Zone Lite baseline

### What is safe to change in-place
- Notification emails (`guardrail_notification_emails`, `cost_notification_emails`).
- Budget thresholds and amount (`budget_thresholds`, `monthly_budget_amount`).
- CloudTrail/Config toggles if you are prepared for drift (disable then destroy if needed).
- Log retention days and CloudWatch log retention.

### Changes that force replacement or manual cleanup
- `name_prefix` and `log_bucket_name` will create new resources and leave old ones.
- KMS key settings may require key policy updates and a scheduled deletion on destroy.
- Disabling Config/CloudTrail after they exist may require explicit stop/cleanup steps.

### Repeat run pattern (changing variables)
1) Update variables (e.g., budget thresholds or emails).
2) Run `terraform plan` and verify in-place updates only.
3) Run `terraform apply`.

### Full cleanup steps
1) Confirm SNS subscriptions are no longer needed; unsubscribe if desired.
2) If AWS Config is enabled, stop the recorder (Terraform handles this on destroy, but it can be manual if needed).
3) Disable CloudTrail logging if needed (Terraform handles this during destroy).
4) Empty the log bucket (including all versions and delete markers) before destroy.
5) Run `terraform destroy` from `use-cases/01-landing-zone-lite/aws/terraform/root`.

### Troubleshooting destroy
- If `aws_ce_anomaly_subscription` fails with "Insufficient subscriber blocks", run destroy with cost controls disabled:
  ```bash
  terraform destroy -var="enable_cost_controls=false"
  ```
- If the log bucket deletion fails with "BucketNotEmpty", delete versioned objects and delete markers, then retry destroy.
  ```bash
  aws s3 rm s3://mcsa-uc01-logs-toolkit-test-389149116969 --recursive
  aws s3api list-object-versions --bucket mcsa-uc01-logs-toolkit-test-389149116969 \
    --query '{Objects: (Versions[].{Key:Key,VersionId:VersionId} + DeleteMarkers[].{Key:Key,VersionId:VersionId})}' \
    --output json > /tmp/mcsa-uc01-log-delete.json
  aws s3api delete-objects --bucket mcsa-uc01-logs-toolkit-test-389149116969 \
    --delete file:///tmp/mcsa-uc01-log-delete.json
  ```

### Partial cleanup (cost controls only)
- Set `enable_cost_controls = false` and apply, or use `terraform destroy -target module.cost_controls`.

---

## UC02 AWS - Inventory + Auto-Documentation

### What is safe to change in-place
- No long-lived infra is created by the workflow itself.
- The discovery IAM policy can be updated in-place.

### Cleanup steps
1) If you no longer need read-only discovery access, run `terraform destroy` in `use-cases/02-inventory-auto-doc/aws/terraform/discovery-access`.
2) Delete old GitHub Actions artifacts if desired.

---

## UC03 AWS - Monitoring Starter

### Cleanup steps
1) Run `terraform destroy` in `use-cases/03-monitoring-starter/aws/terraform/root`.
2) Confirm SNS subscriptions are removed if you no longer want alerts.
3) If you created or purged SQS messages during testing, no additional cleanup is required.

---

## UC04 AWS - Ephemeral Sandbox

### Cleanup steps
1) Destroy the stack in `use-cases/04-ephemeral-sandbox/aws/terraform/root` using a destroy plan.
2) Confirm the DynamoDB sandbox record is gone; TTL expires automatically if configured.
3) Budgets and anomaly monitors are removed by the destroy.
4) If a leftover SNS topic or Container Insights log group remains, delete it manually after the destroy.

---

## UC05 - Identity Bootstrap for Automation

### What is safe to change in-place
- Subject claim patterns and role descriptions can be updated in-place.

### Cleanup steps
1) `terraform destroy` in the cloud-specific folder:
   - AWS: `use-cases/05-identity-bootstrap-automation/aws/terraform/oidc-bootstrap`
   - Azure: `use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap`
   - GCP: `use-cases/05-identity-bootstrap-automation/gcp/terraform/oidc-bootstrap`
2) Remove any GitHub repo variables/secrets referencing these roles.
