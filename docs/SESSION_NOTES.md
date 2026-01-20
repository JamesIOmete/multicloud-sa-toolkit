# Session Notes — 2026-01-19

## Status Recap
- UC01 AWS baseline validated (CloudTrail logging, AWS Config recording, SNS topics confirmed).
- UC02 AWS inventory workflow re-run successfully; artifacts stored locally under out/latest.
- Documentation updated and committed (discovery IAM role prerequisite, validation notes); changes pushed to origin/master.

## Pending Work
1. **UC03 — Monitoring and Alerting Starter Pack**
   - Terraform scaffolding committed under `use-cases/03-monitoring-starter/aws/`.
   - Local validation completed on 2026-01-20 (alarms fired, email received).
   - Next: automate proof workflow in GitHub Actions after UC04 planning.

2. **UC04 — Ephemeral Sandbox Factory**
   - Define sandbox structure (VPC, guardrails, cost controls) with TTL enforcement.
   - Determine sandbox size, default TTL, and whether to provision in current account or a dedicated sandbox account.

## Information Needed from User
- UC04: provide desired sandbox resource scope (compute/storage) and confirm when to create dedicated sandbox account.
- Environment strategy: confirm timing for moving to dedicated sandbox account versus continuing in current account.

## Next Steps (after inputs)
- Scaffold UC03/UC04 directories and Terraform code.
- Implement monitoring alarms, sandbox lifecycle, documentation, and local validation scripts.
- Once ready, update docs/USE_CASES.md and create proof workflows, then request approval to run.
