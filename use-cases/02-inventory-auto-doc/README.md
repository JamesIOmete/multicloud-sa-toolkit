# Use Case 02 - Environment Inventory + Auto-Documentation (MVP)

Generate a portable inventory of your cloud environment and a plain-language summary that you can attach to reviews, audits, or onboarding docs.

## What it does
- Captures a machine-readable snapshot of key resources (network, compute, IAM) in `inventory.json`.
- Writes a teammate-friendly `SUMMARY.md` so reviewers do not need to read raw JSON.
- Packages both files as GitHub Actions artifacts for easy download and sharing.

## When to run it
- On demand before architecture reviews, migrations, incident postmortems, or quarterly governance checks.
- Any time you need a current-state picture without granting broad console access to stakeholders.

## Implementations
- AWS: aws/docs/README.md (current reference implementation)
- Azure: planned
- GCP: planned
