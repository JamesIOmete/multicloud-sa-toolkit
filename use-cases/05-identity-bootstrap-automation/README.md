# Use Case 05 - Identity Bootstrap for Automation

Establish secure GitHub Actions to cloud trust so CI/CD pipelines can run Terraform without storing long-lived cloud keys.

## What it does (AWS, Azure, GCP variants)
- Provisions an OpenID Connect trust between GitHub Actions and the target cloud.
- Creates least-privilege automation roles or service principals for Terraform plans and applies.
- Documents the required GitHub repository variables and secrets to activate the trust.
- Optionally provides local helper roles for break-glass or validation.

## When to run it
- Run once per cloud/account or subscription before enabling any GitHub-based Terraform workflows.
- Re-run when rotating trust policies, adding new repositories, or expanding allowed environments/branches.
- Not designed for day-to-day execution; it is a foundational setup step for your automation platform.

## Why it matters for solution architects
- Removes the need to store static cloud credentials inside GitHub, aligning with security best practices.
- Sets a consistent pattern that every other use case in this toolkit can reference.
- Gives teams a documented onboarding path when they want to run Terraform from GitHub Actions.

## Implementations
- AWS: terraform definitions under `aws/terraform/`
- Azure: terraform definitions under `azure/terraform/`
- GCP: terraform definitions under `gcp/terraform/`

Detailed per-cloud runbooks will live in `aws/docs/`, `azure/docs/`, and `gcp/docs/` as they are authored.
