# Tasks and Session History

Last updated: 2026-01-15

## Active focus
- Review use cases, confirm validation status, and capture cleanup guidance for repeatable AWS runs.

## Backlog (from roadmap)
### Repo resettlement
- Move existing stacks under use-cases/05-identity-bootstrap-automation
- Keep workflows runnable in .github/workflows (prefix with uc##)
- Remove Terraform state from git tracking; ignore tfstate files
- Add use case index + roadmap + decisions docs

### Next: Use Case 02 (AWS) — Inventory + Auto-Documentation
- Define inventory schema (inventory.json + SUMMARY.md)
- Add least-priv discovery policy attached to GitHub OIDC role
- Add discovery script + GitHub Actions workflow uploading artifacts

## Recently completed
- (none tracked here yet)

## Session history
- 2026-01-15: created TASKS.md to track goals and progress across sessions
- 2026-01-15: started review of existing use cases, validation status, and AWS cleanup guidance
- 2026-01-15: ran `tools/ci/validate.sh`; failed at terraform fmt check (2 files need formatting)
- 2026-01-15: ran `terraform fmt` on UC02/UC05 Terraform; reran `tools/ci/validate.sh` and hit duplicate output errors in UC01 modules plus provider download blocked by sandbox, command timed out
- 2026-01-15: removed duplicate outputs in UC01 modules; reran `tools/ci/validate.sh` with network access, hit AWS budgets/anomaly schema errors in UC01 cost-controls and the command timed out
- 2026-01-15: updated UC01 cost-controls for current AWS provider schema, ran `tools/ci/validate.sh` successfully (aws oidc-bootstrap printed a credential warning but validate passed)
- 2026-01-15: ran UC01 plan with cascadiaio profile; after fixing anomaly threshold match option, plan succeeded (31 to add)
- 2026-01-15: attempted UC01 apply; partial resources created, apply failed with SNS policy error, duplicate budget name, anomaly subscription frequency vs SNS, S3 bucket policy conditions, missing AWS Config role policy ARN, and KMS permissions for CloudWatch Logs
- 2026-01-15: fixed UC01 cost-controls SNS principal, anomaly subscription, bucket policy, KMS policy, Config policy ARN, and CloudTrail log group ARN; imported budget; UC01 apply completed successfully
