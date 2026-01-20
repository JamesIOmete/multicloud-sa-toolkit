# Multi-Cloud SA Toolkit — Use Cases

Status legend:
- ✅ implemented + validated
- 🧱 implemented (validation pending)
- 🔜 planned

## UC05 — Identity bootstrap for automation (GitHub Actions OIDC → Cloud)
**Goal:** enable CI to run Terraform without long-lived cloud keys.

- AWS: ✅
- Azure: 🧱
- GCP: 🧱

Entry point:
- `use-cases/05-identity-bootstrap-automation/`

## UC02 — Environment inventory + auto-documentation (“what’s here and how is it wired?”)
**Goal:** produce portable artifacts (`inventory.json`, `SUMMARY.md`) that help with migrations, reviews, incident context, and onboarding.


Doc entry point (AWS):

Notes:


## UC03 — Monitoring and alerting starter pack (token workloads + CloudWatch alerts)
**Goal:** provide baseline monitoring for representative workloads (queue backlog, processing delays) and wire alerts to email.

- AWS: ✅
- Azure: 🔜
- GCP: 🔜

Doc entry point (AWS):
- `use-cases/03-monitoring-starter/aws/docs/README.md`

Notes:
- Token SQS workload with CloudWatch dashboard and alarms targeting SNS email.
- Latest validation: AWS stack applied and alarms triggered locally on 2026-01-20.
Sample output (sanitized):
- `use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md`
- `use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json`

## UC01 — Landing Zone Lite baseline (guardrails + logging + cost controls)
**Goal:** deliver a minimum governance baseline before workloads land in an account.

- AWS: ✅
- Azure: 🔜
- GCP: 🔜

Doc entry point (AWS):
- `use-cases/01-landing-zone-lite/aws/docs/README.md`

Notes:
- Validation checks confirmed CloudTrail logging, AWS Config recording, and SNS topics operational as of 2026-01-19.

## Upcoming
- UC04 - Ephemeral sandbox factory (repeatable low-cost environments)
