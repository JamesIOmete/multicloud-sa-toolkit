# UC03 AWS — Monitoring & Alerting Starter Pack

Establish baseline monitoring for token workloads that simulate real production patterns. Provision a CloudWatch dashboard, SQS workload, and alarms wired to email notifications.

---

## What this stack creates
- Token SQS queue representing an application work backlog.
- CloudWatch Logs group for application output (placeholder for workload logs).
- CloudWatch alarms:
  - Queue depth (`ApproximateNumberOfMessagesVisible`).
  - Oldest message age (`ApproximateAgeOfOldestMessage`).
- CloudWatch dashboard visualizing queue depth and aging.
- SNS topic + email subscriptions (if an external ARN is not provided).

All resources are tagged with `toolkit = multicloud-sa-toolkit`, `use_case = 03-monitoring-starter`, `env = <var.env>`, and `owner = <var.owner>`.

---

## Prerequisites
1. **Identity bootstrap (UC05)** completed so GitHub Actions can assume the `github-terraform-oidc` role.
2. **Notification email** ready to confirm SNS subscription (example: `jward448@gmail.com`).
3. **Backend configuration** (optional) stored locally if using an S3 backend: copy `backend/aws-uc03-monitoring.hcl.example` to `backend/aws-uc03-monitoring.hcl` and set your bucket/account values.
4. Terraform CLI `>= 1.6` and AWS provider `>= 5.0`.

---

## Terraform layout
```
use-cases/03-monitoring-starter/aws/terraform/
  root/                  # Composes token workload + alarms
  modules/
    token-workloads/     # SQS queue + CloudWatch Logs group
    alarms/              # CloudWatch alarms + dashboard
```

---

## Quick start (local apply)
```bash
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true

cd use-cases/03-monitoring-starter/aws/terraform/root
terraform init -reconfigure -backend-config=../../../../../backend/aws-uc03-monitoring.hcl
terraform plan -var "notification_emails=[\"jward448@gmail.com\"]"
terraform apply
```

Confirm the SNS subscription from your email inbox. After apply, inspect:
- CloudWatch dashboard `mcsa-uc03-<env>-starter-dashboard`.
- SQS queue `mcsa-uc03-<env>-app-queue`.
- Alarms `mcsa-uc03-<env>-queue-depth` and `mcsa-uc03-<env>-queue-age`.

---

## Simulating activity
To exercise the alarms locally:
1. **Publish messages to the queue** to push depth over the threshold:
   ```bash
   aws sqs send-message-batch \
     --profile james-terraform \
     --queue-url $(aws sqs get-queue-url --queue-name mcsa-uc03-toolkit-test-app-queue --profile james-terraform --query QueueUrl --output text) \
     --entries 'Id=1,MessageBody=test1' 'Id=2,MessageBody=test2' 'Id=3,MessageBody=test3'
   ```
2. **Optional delay**: use `--delay-seconds` to inflate the oldest message age metric.
3. Monitor alarm transitions in the CloudWatch console or via `aws cloudwatch describe-alarms`.
4. After tests, purge the queue: `aws sqs purge-queue --queue-url <QUEUE_URL>`.

### Validation snapshot (2026-01-20)
- Alarm `mcsa-uc03-toolkit-test-queue-age` entered `ALARM` after message age 184 seconds.
- Alarm `mcsa-uc03-toolkit-test-queue-depth` returned to `OK` once backlog drained.
- Email notification received at `jward448@gmail.com` confirming SNS subscription and alarm firing.

---

## Cleanup
```bash
terraform destroy
```
SNS subscriptions created via Terraform remain until destroyed; confirm removal if you no longer want alerts.

---

## Next steps
- Extend the token workload with synthetic Lambda or ECS tasks to simulate real services.
- Add alarms that reuse budgets/cost anomaly signals from UC01 for unified alerting.
- Prepare a GitHub Actions proof workflow that runs `terraform plan` to ensure configuration stays healthy.
