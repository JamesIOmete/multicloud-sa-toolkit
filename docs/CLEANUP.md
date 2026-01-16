# Cleanup and Repeatability

This guide explains how to safely repeat runs with different variables, and how to clean up artifacts created by each use case.

## General guidance
- Prefer `terraform apply` with updated variables for in-place changes.
- When changing naming/prefix variables, expect replacements and manual cleanup.
- S3 log buckets are versioned and not `force_destroy`; empty them before `terraform destroy`.
- KMS keys have deletion windows; full removal is delayed by AWS.
- If an apply fails, re-run `terraform apply` after fixing the error; Terraform will converge.

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
4) Empty the log bucket (including all versions) before destroy.
5) Run `terraform destroy` from `use-cases/01-landing-zone-lite/aws/terraform/root`.

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

## UC05 - Identity Bootstrap for Automation

### What is safe to change in-place
- Subject claim patterns and role descriptions can be updated in-place.

### Cleanup steps
1) `terraform destroy` in the cloud-specific folder:
   - AWS: `use-cases/05-identity-bootstrap-automation/aws/terraform/oidc-bootstrap`
   - Azure: `use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap`
   - GCP: `use-cases/05-identity-bootstrap-automation/gcp/terraform/oidc-bootstrap`
2) Remove any GitHub repo variables/secrets referencing these roles.

