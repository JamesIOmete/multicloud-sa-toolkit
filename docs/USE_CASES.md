# Multi-cloud SA Toolkit - Use Cases

## UC05 - Identity bootstrap for automation (GitHub Actions OIDC to cloud)
- Goal: enable keyless Terraform automation from GitHub Actions into each cloud.
- Status: AWS implemented; Azure and GCP implementations present, validation pending.
- Docs: use-cases/05-identity-bootstrap-automation/

## UC02 - Environment inventory and auto-documentation ("what is here and how is it wired?")
- Goal: map accounts, networks, ingress or egress, key services, IAM boundaries, and monitoring coverage.
- Status: AWS implementation live; Azure and GCP planned.
- Doc entry point: use-cases/02-inventory-auto-doc/aws/docs/README.md
- Sample output (sanitized):
  - use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md
  - use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json

## Upcoming
- UC01 - Landing Zone Lite baseline (guardrails, logging, cost controls)
- UC03 - Monitoring and alerting starter pack (golden signals plus cost anomaly alerts)
- UC04 - Ephemeral sandbox factory (repeatable low-cost environments)
