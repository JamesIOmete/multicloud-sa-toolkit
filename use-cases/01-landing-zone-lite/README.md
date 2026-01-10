# Use Case 01 - Landing Zone Lite Baseline

A starter landing zone for AWS accounts that need guardrails, centralized logging, and cost visibility before any workloads are deployed.

## What it creates (AWS v1 scope)
- Account guardrails using AWS Organizations SCPs or account-level controls to block risky actions (for example disabling CloudTrail or creating internet-open security groups).
- Central logging pipeline (CloudTrail + CloudWatch Logs or S3) so every account action is captured and reviewable.
- Cost controls such as AWS Budgets alerts to surface spend spikes early.
- Supporting IAM roles and policies required to operate and observe the baseline.

## When to run it
- Run once for every new AWS account before other automation or workloads are added; it establishes a known-good security and logging foundation.
- Re-run when you need to update the baseline (new guardrail rules, new logging destinations, revised budget thresholds).
- Do not schedule it to run continuously; it is a configuration baseline, not a drift enforcer.

## Why it matters for solution architects
- Ensures that later use cases (inventory, monitoring, sandbox factories) inherit a consistent, compliant starting point.
- Gives stakeholders immediate proof that guardrails, logging, and cost alerts are active.
- Reduces the manual checklist needed during account onboarding.

## Implementations
- AWS: planned (documents will live in `aws/docs/README.md` once modules are ready)
- Azure: planned
- GCP: planned
