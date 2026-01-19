# UC02 AWS — Inventory + Auto-Documentation (MVP)

This use case generates an AWS environment inventory (`inventory.json`) and a summary (`SUMMARY.md`) using a GitHub Actions workflow.

---

## How it works
1. GitHub Actions workflow runs on demand (`workflow_dispatch`).
2. Workflow assumes an AWS IAM Role via GitHub OIDC:
   - IAM role: `github-terraform-oidc`
   - GitHub repo variable: `AWS_OIDC_ROLE_ARN`
3. Workflow runs discovery and writes outputs:
   - `out/inventory.json`
   - `out/SUMMARY.md`
4. Workflow uploads outputs as a GitHub Actions artifact.

---

## One-time setup

### Prerequisite: UC05 (Identity bootstrap)
UC02 expects the GitHub OIDC provider + role to already exist (Use Case 05).

Also ensure GitHub Actions has this repo variable set:
- `AWS_OIDC_ROLE_ARN = arn:aws:iam::<ACCOUNT_ID>:role/github-terraform-oidc`

### Organizations discovery assume role
Local operators need an IAM role they can assume to read AWS Organizations metadata. Create one time:

1. Copy `docs/org-discovery-trust.json` and `docs/org-discovery-policy.json` locally.
2. Replace `<ACCOUNT_ID>` with your AWS account ID and adjust the IAM user name if you do not use `james-terraform`.
3. Apply with an administrator profile:

```bash
AWS_PROFILE=admin-profile aws iam create-role \
   --role-name org-discovery-readonly \
   --assume-role-policy-document file://org-discovery-trust.json

AWS_PROFILE=admin-profile aws iam put-role-policy \
   --role-name org-discovery-readonly \
   --policy-name OrgDiscoveryReadOnly \
   --policy-document file://org-discovery-policy.json
```

4. Test from the limited CLI profile (example: `james-terraform`):

```bash
AWS_PROFILE=james-terraform aws sts assume-role \
   --role-arn arn:aws:iam::<ACCOUNT_ID>:role/org-discovery-readonly \
   --role-session-name org-discovery-check
```

Successful assume-role verifies the discovery scripts will be able to list the organization hierarchy.

### Backend requirement (AWS S3 state)
If you use an S3 backend for this Terraform stack, the referenced S3 bucket **must already exist**.

Recommended local backend config file (do not commit if it contains real bucket names):
- `backend/aws-uc02-discovery.hcl.example` (copy to `backend/aws-uc02-discovery.hcl`, ignored by git)

Example:
```hcl
bucket       = "multicloud-sa-toolkit-tfstate-<ACCOUNT_ID>"
region       = "us-west-2"
encrypt      = true
key          = "use-cases/02-inventory-auto-doc/aws/discovery-access/terraform.tfstate"
use_lockfile = true
profile      = "james-terraform"
```

### Attach discovery permissions (read-only)
Terraform stack:
- `use-cases/02-inventory-auto-doc/aws/terraform/discovery-access`

Creates:
- IAM policy: `github-oidc-discovery-readonly`
- Attaches it to role: `github-terraform-oidc`

Apply (local):
```bash
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true

cd use-cases/02-inventory-auto-doc/aws/terraform/discovery-access
terraform init -reconfigure -backend-config=../../../../../backend/aws-uc02-discovery.hcl
terraform apply
```

---

## Run (GitHub Actions)
Workflow file:
- `.github/workflows/uc02-aws-inventory.yml`

Run it:
- GitHub → Actions → `uc02-aws-inventory` → **Run workflow**
- Download artifact `uc02-aws-inventory`

Artifact contains:
- `inventory.json`
- `SUMMARY.md`

---

## Sample output (sanitized)
- `use-cases/02-inventory-auto-doc/aws/sample-output/SUMMARY.sample.md`
- `use-cases/02-inventory-auto-doc/aws/sample-output/inventory.sample.json`

## When to run it
- Trigger the workflow before architecture reviews, migration planning, or handoffs so you have current-state artifacts.
- Run after significant infrastructure changes to keep an audit trail of what is live.
- Use it for incident response prep or post-incident summaries so responders have fast context.

## What you get
- `inventory.json` for automation, diffing, or feeding other tools.
- `SUMMARY.md` for stakeholders who prefer a narrated overview.
- Evidence that the GitHub Actions OIDC role remains scoped to read-only operations (built into the Terraform policy).

---

## Recommended security/auth configuration
- CI uses OIDC; do **not** store AWS access keys in GitHub.
- Discovery policy is read-only and scoped to Describe/List calls.

Do not commit:
- `terraform.tfstate*`
- `.terraform/`
- `backend/*.hcl` that contain real bucket names

---

## Cleanup and repeatability
See `docs/CLEANUP.md` for repeatable run guidance and cleanup steps.
