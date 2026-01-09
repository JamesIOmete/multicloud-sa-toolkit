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

- AWS: ✅
- Azure: 🔜
- GCP: 🔜

Doc entry point (AWS):
- `use-cases/02-inventory-auto-doc/aws/docs/README.md`

Sample output (sanitized):
- `use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md`
- `use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json`

## Upcoming
- UC01 — Landing Zone Lite baseline (guardrails + logging + cost controls)
- UC03 — Monitoring & alerting starter pack (golden signals + cost anomaly alerts)
- UC04 — Ephemeral sandbox factory (repeatable low-cost environments)
