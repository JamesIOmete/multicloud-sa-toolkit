# Use Case 04 – Ephemeral Sandbox Factory

This runbook explains how to provision a short-lived sandbox environment in AWS using the UC04 Terraform modules. The stack deploys opinionated networking, a sample Fargate workload, DynamoDB-backed metadata tracking with TTL, and cost guardrails (budget plus optional anomaly detection) aligned with the toolkit’s tagging conventions.

## Prerequisites

- Terraform >= 1.6 and AWS provider >= 5.0
- AWS credentials scoped to create VPC, ECS, ALB, DynamoDB, Budgets, and Cost Explorer resources in the target account (we use the `james-terraform` profile)
- An SNS topic ARN for alerts (defaults to the UC01 topic if provided)
- Backend configuration (copy from `backend/aws-uc01-landing-zone.hcl.example` or your preferred backend)
- Optional: existing DynamoDB table with TTL enabled if you disable table creation

## Deployment Steps

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values:
   - `sandbox_id` distinguishes each sandbox deployment (e.g., `uc04-sbx01`, `uc04-sbx02`)
   - Set `alert_topic_arn` if you have a sandbox-specific SNS topic; leave blank to fall back to UC01 alerts
   - Tune `ttl_hours` to align with sandbox lifetime policies
   - Leave `container_port` at `80` for the sample httpd image; adjust only if you supply a custom workload
   - Flip `enable_cost_anomaly_monitor` to `true` only if the account has remaining Cost Explorer anomaly monitor quota
2. Configure Terraform backend:
   - Copy an existing backend config, update names, and reference via `terraform init -backend-config=...`
3. Initialize the working directory (one-time or after provider upgrades):
   ```bash
   AWS_PROFILE=james-terraform terraform init -upgrade
   ```
4. Create and review a saved plan (ensures apply uses the exact actions you inspected):
   ```bash
   AWS_PROFILE=james-terraform terraform plan -var-file=terraform.tfvars -out plan.tfplan
   ```
5. Apply the saved plan immediately after review:
   ```bash
   AWS_PROFILE=james-terraform terraform apply plan.tfplan
   ```
6. Verify after apply:
   - Retrieve outputs with `AWS_PROFILE=james-terraform terraform output`
   - Capture the ALB endpoint: `ALB_DNS=$(AWS_PROFILE=james-terraform terraform output -raw alb_dns_name)`
   - Test the workload: `curl http://$ALB_DNS` (expect HTTP 200 and the Apache "It works!" page)
   - Confirm the DynamoDB table lists the sandbox item with an `expires_at` epoch value
   - Verify the monthly budget exists in the AWS Billing console (an anomaly subscription is only present when enabled)

## Cleanup

- Destroy the stack when the sandbox expires:
   ```bash
   AWS_PROFILE=james-terraform terraform plan -destroy -var-file=terraform.tfvars -out destroy.tfplan
   AWS_PROFILE=james-terraform terraform apply destroy.tfplan
   ```
- Confirm the DynamoDB item is removed; TTL expiration occurs automatically. If you used an existing table, ensure you clean up any orphaned items.
- Budgets and anomaly monitors are removed with the Terraform destroy.
- Re-run `AWS_PROFILE=james-terraform terraform output` after destroy to ensure no residual outputs remain.

## Notes

- NAT gateway is disabled by default to minimize cost; enable via `enable_nat_gateway = true` for workloads that need outbound access from private subnets.
- Container Insights is on by default. Disable if CloudWatch metric costs are a concern.
- Monthly budget defaults to $25 with an 80% forecast alarm and $10 anomaly threshold—tune per account policy. Cost anomaly monitoring is optional and off by default due to AWS account limits.
- Tags follow the toolkit standard (`toolkit`, `use_case`, `env`, `owner`, `sandbox_id`). Add custom tags via `additional_tags`.
- The Fargate target group uses `create_before_destroy` to avoid listener conflicts during updates; applying immediately after planning prevents stale-plan errors.
- ECS deployments follow standard rolling replacement—removing the `ignore_changes` lifecycle ensures new task definitions roll out automatically when the container port or image changes.
- For quick health checks, run `watch -n 15 "AWS_PROFILE=james-terraform aws ecs describe-services --cluster <cluster> --services <service> --query 'services[0].[desiredCount,runningCount,events[0].message]' --output text"` to monitor desired vs running tasks and latest events.
