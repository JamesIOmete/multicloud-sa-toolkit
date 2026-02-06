# Use Case 05 — AWS — Identity Bootstrap for Automation (GitHub Actions OIDC → AWS)

This runbook establishes **keyless** authentication from **GitHub Actions** to **AWS** using **OIDC** (no long‑lived AWS access keys stored in GitHub).

UC01–UC04 (AWS) assume UC05 is complete.

---

## References

- Prereqs: `docs/PREREQS.md`
- Workflows: `docs/WORKFLOWS.md`
- Use case index: `docs/USE_CASES.md`
- Cleanup: `docs/CLEANUP.md`

---

## 1) What this stack creates

Terraform in:

`use-cases/05-identity-bootstrap-automation/aws/terraform/oidc-bootstrap`

creates the AWS identity objects needed so GitHub Actions can assume an AWS role using OIDC:

- **IAM OIDC Provider** for GitHub Actions (`https://token.actions.githubusercontent.com`)  
  *(if your account doesn’t already have one)*
- **IAM Role** (the “OIDC role”) with a trust policy allowing `sts:AssumeRoleWithWebIdentity`
- **IAM policy attachments** that grant the role permissions required by later use cases  
  (scope depends on the toolkit’s design for AWS UC01–UC04)

**Key output:** the role ARN that GitHub Actions will assume.

---

## 2) Prerequisites

### Tools
- `terraform` (recommended: 1.6+; newer is fine)
- `aws` CLI (recommended for verification, optional if you only use workflows)
- `gh` CLI (recommended: to set GitHub Actions variables and run workflows)

### Access / Permissions
You need AWS permissions that can:
- Create / update IAM roles and policies
- Create an IAM OIDC provider **if** one does not already exist
- Attach policies to roles

Practically, this is usually an admin‑level permission set in a test account.

### GitHub repository requirements
- GitHub Actions enabled
- Workflows include:
  ```yaml
  permissions:
    id-token: write
    contents: read
  ```
  so Actions can request an OIDC token.

---

## 3) Terraform layout

```
use-cases/05-identity-bootstrap-automation/aws/
├── docs/
│   └── README.md
└── terraform/
    └── oidc-bootstrap/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

---

## 4) Configure backend (recommended)

This repo uses remote state. For AWS stacks, the backend is typically S3 (+ DynamoDB lock), configured via an HCL backend file in `backend/`.

Example files exist under `backend/` with the `.example` suffix (copy to a local `.hcl` file that is gitignored in this repo).

From repo root, you’ll generally run `terraform init` with a `-backend-config=` file.

---

## 5) Step-by-step: AWS UC05

### 5.1 — Select the stack folder

From repo root:

```bash
cd use-cases/05-identity-bootstrap-automation/aws/terraform/oidc-bootstrap
```

### 5.2 — Set required Terraform variables

This stack typically requires:
- `github_org`
- `github_repo`

Set them either via environment variables:

```bash
export TF_VAR_github_org="YOUR_GITHUB_ORG"
export TF_VAR_github_repo="YOUR_GITHUB_REPO"
```

…or via `terraform.tfvars` in the stack directory (do **not** commit secrets).

### 5.3 — Initialize Terraform

If you have an AWS backend config file:

```bash
terraform init -backend-config=../../../../../backend/aws-uc05-identity-bootstrap.hcl
```

If you don’t have a backend config yet, initialize with local state (fine for experimentation):

```bash
terraform init
```

### 5.4 — Plan and apply

```bash
terraform plan -out tfplan
terraform apply tfplan
```

### 5.5 — Capture outputs you will need later

At minimum, capture the **OIDC role ARN** (used by workflows):

```bash
terraform output
```

Look for an output like `aws_oidc_role_arn` / `role_arn` (exact name depends on the module).

---

## 6) Configure GitHub Actions variables

The AWS UC05 workflow uses GitHub Actions **variables** (not secrets) for identifiers like the role ARN.

Set the role ARN variable expected by the workflow (commonly `AWS_OIDC_ROLE_ARN`):

```bash
gh variable set AWS_OIDC_ROLE_ARN   --repo <ORG>/<REPO>   --body "<ROLE_ARN_FROM_TERRAFORM_OUTPUT>"
```

Confirm:

```bash
gh variable list --repo <ORG>/<REPO> | grep -E '^AWS_OIDC_ROLE_ARN'
```

---

## 7) Validate (UC05 AWS smoke workflow)

This repo includes the AWS OIDC smoke workflow:

- `.github/workflows/uc05-aws-smoke.yml`
- Workflow name in YAML is typically: `aws-oidc-smoke`

### 7.1 — Run the workflow

```bash
gh workflow run aws-oidc-smoke --repo <ORG>/<REPO>
```

### 7.2 — Watch and inspect logs

```bash
gh run list --repo <ORG>/<REPO> --workflow uc05-aws-smoke.yml --limit 1
gh run watch <RUN_ID> --repo <ORG>/<REPO> --exit-status
gh run view <RUN_ID>  --repo <ORG>/<REPO> --log
```

### 7.3 — “Proof” check

The run logs should show the job is using an **assumed role** (OIDC), e.g. STS caller identity / assumed-role text:

```bash
gh run view <RUN_ID> --repo <ORG>/<REPO> --log | grep -E "assumed-role|sts|get-caller-identity" -n || true
```

---

## 8) Troubleshooting

### A) `AccessDenied` or “not authorized to perform sts:AssumeRoleWithWebIdentity”
Most common causes:
- The IAM role trust policy does not match the workflow `sub` claim (repo/org/branch/ref)
- The workflow is running from a different branch than the trust policy allows
- The workflow is missing `permissions: id-token: write`

### B) Wrong branch (`main` vs `master`)
If the trust policy is restricted to one branch but the repo default is different, update the Terraform variables / trust policy conditions to include the branch you actually run on.

### C) Existing OIDC provider conflicts
If your account already has the GitHub OIDC provider, the stack may need to “detect and reuse” it instead of creating a second one. Review `main.tf` and variables.

---

## 9) Cleanup

Only destroy UC05 when you no longer need GitHub Actions OIDC access for AWS:

```bash
terraform destroy
```

Also consider removing GitHub Actions variables you added (optional):

```bash
gh variable delete AWS_OIDC_ROLE_ARN --repo <ORG>/<REPO>
```
