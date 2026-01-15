# Agent Guidance

## Command approvals
- Ask before any `terraform apply`, `gh workflow run`, or cloud-CLI commands (`aws`, `az`, `gcloud`).
- Ask before any command that writes outside the repo or requires network access.
- After important code changes and testing, offer to push updates to GitHub with a clear commit message. If approved, run `git add`, `git commit`, and `git push`.

## Validation defaults
- Do not run tests or validation unless explicitly requested.
- If asked to validate, prefer:
  - `tools/ci/validate.sh`
  - `terraform fmt -check`
  - `terraform validate`

## State and credentials
- Do not read or modify local credential files.
- Do not edit or commit any `terraform.tfstate*` or `.terraform/` content.
- Treat backend configs containing real resource names as local-only.
