# UC02 AWS - Inventory + Auto-Documentation (MVP)

This UC generates an AWS environment inventory (inventory.json) and a summary (SUMMARY.md) using a GitHub Actions workflow.

---

## How it works

1. GitHub Actions workflow runs on demand (workflow_dispatch).
2. Workflow assumes an AWS IAM Role via GitHub OIDC:
   - IAM role: github-terraform-oidc
   - GitHub repo variable: AWS_OIDC_ROLE_ARN
3. Workflow executes discovery and writes outputs:
   - out/inventory.json
   - out/SUMMARY.md
4. Workflow uploads outputs as an artifact.

---

## One-time setup

### Prerequisite: UC05 (Identity bootstrap)
UC02 expects GitHub OIDC bootstrap is complete (Use Case 05) and the repo variable is set:

- AWS_OIDC_ROLE_ARN = arn:aws:iam::<ACCOUNT_ID>:role/github-terraform-oidc

### Attach discovery permissions (read-only)
Terraform stack:
- use-cases/02-inventory-auto-doc/aws/terraform/discovery-access

Creates:
- IAM policy: github-oidc-discovery-readonly
- Attaches to role: github-terraform-oidc

Recommended backend config (local file, not committed):
- backend/aws-uc02-discovery.hcl

Example:
```hcl
bucket       = "multicloud-sa-toolkit-tfstate-<ACCOUNT_ID>"
region       = "us-west-2"
encrypt      = true
key          = "use-cases/02-inventory-auto-doc/aws/discovery-access/terraform.tfstate"
use_lockfile = true
profile      = "james-terraform"
```

Apply (local):

```
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true

cd use-cases/02-inventory-auto-doc/aws/terraform/discovery-access
terraform init -reconfigure -backend-config=../../../../../backend/aws-uc02-discovery.hcl
terraform apply
```

## Run (GitHub Actions)

Workflow:
- .github/workflows/uc02-aws-inventory.yml

Run it:
- GitHub > Actions > uc02-aws-inventory
- Run workflow

Download artifact uc02-aws-inventory. Artifact contains:
- inventory.json
- SUMMARY.md

## Sample output (sanitized)
- use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md
- use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json

## Recommended security/auth configuration
- CI uses OIDC; do not store AWS access keys in GitHub.
- Discovery policy is read-only and scoped to Describe/List calls.

Do not commit:
- terraform.tfstate*
- .terraform/
- backend/*.hcl that contain real bucket names
