# Multi-Cloud SA Toolkit — Use Cases

Status legend:
- ✅ implemented + validated
- 🧱 implemented (validation pending)
- 🔜 planned

## UC05 — Identity bootstrap for automation (GitHub Actions OIDC → Cloud)
**Goal:** enable CI to run Terraform without long-lived cloud keys.

- AWS: ✅
- Azure: 🧱
- GCP: ✅

Entry point:
- `use-cases/05-identity-bootstrap-automation/`

Notes:
- Validated GitHub Actions → AWS OIDC path exercises UC01 guardrails and cost controls.

## UC02 — Environment inventory + auto-documentation (“what’s here and how is it wired?”)
**Goal:** produce portable artifacts (`inventory.json`, `SUMMARY.md`) that help with migrations, reviews, incident context, and onboarding.

- AWS: ✅
- Azure: 🧱
- GCP: ✅

Doc entry point (AWS):
- `use-cases/02-inventory-auto-doc/aws/docs/README.md`
Doc entry point (Azure):
- `use-cases/02-inventory-auto-doc/azure/docs/README.md`
Doc entry point (GCP):
- `use-cases/02-inventory-auto-doc/gcp/docs/README.md`

Notes:
- Includes scripted discovery under `aws/scripts/discover.sh` and sample output in `aws/sample-output/`.
- Latest validation: inventory + summary generated against toolkit test account on 2026-01-18.

Sample output (sanitized):
- `use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md`
- `use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json`

## UC03 — Monitoring and alerting starter pack (token workloads + CloudWatch alerts)
**Goal:** provide baseline monitoring for representative workloads (queue backlog, processing delays) and wire alerts to email.

- AWS: ✅
- Azure: 🔜
- GCP: ✅

Doc entry point (AWS):
- `use-cases/03-monitoring-starter/aws/docs/README.md`
Doc entry point (GCP):
- `use-cases/03-monitoring-starter/gcp/docs/README.md`

Notes:
- Token SQS workload with CloudWatch dashboard and alarms targeting SNS email.
- Latest validation: AWS stack applied and alarms triggered locally on 2026-01-20.

## UC04 — Ephemeral sandbox factory (repeatable low-cost environments)
**Goal:** deliver a short-lived application sandbox (VPC, Fargate service, budget guardrails, metadata store) that can be spun up and torn down quickly.

- AWS: ✅
- Azure: 🔜
- GCP: ✅

Doc entry point (AWS):
- `use-cases/04-ephemeral-sandbox/aws/docs/README.md`
Doc entry point (GCP):
- `use-cases/04-ephemeral-sandbox/gcp/docs/README.md`

Notes:
- Terraform modules cover networking, Fargate, metadata tracking, and cost controls with a validated runbook (updated 2026-01-20).
- Default configuration keeps NAT optional; docs outline ALB verification and destroy workflow.

## UC01 — Landing Zone Lite baseline (guardrails + logging + cost controls)
**Goal:** deliver a minimum governance baseline before workloads land in an account.

- AWS: ✅
- Azure: 🧱
- GCP: ✅

Doc entry point (AWS):
- `use-cases/01-landing-zone-lite/aws/docs/README.md`
Doc entry point (Azure):
- `use-cases/01-landing-zone-lite/azure/docs/README.md`
Doc entry point (GCP):
- `use-cases/01-landing-zone-lite/gcp/docs/README.md`

Notes:
- Validation checks confirmed CloudTrail logging, AWS Config recording, and SNS topics operational as of 2026-01-19.

## Upcoming
- Azure/GCP parity for UC01–UC04
- Validation runs for UC05 Azure path
