# Use Case 05 — Azure — Identity Bootstrap for Automation (GitHub Actions OIDC → Azure)

This runbook establishes **keyless** authentication from **GitHub Actions** to **Azure** using **OIDC federated credentials** (no long-lived client secrets).

It is a prerequisite for **UC01–UC04 (Azure)** because those Terraform runs/workflows assume OIDC auth already exists.

---

## 1) What this stack creates

Terraform in:

```text
use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap
```

creates:

- **Entra ID App Registration** (`azuread_application`)
- **Service Principal** for that application (`azuread_service_principal`)
- **Federated Identity Credentials (FICs)** for one or more GitHub OIDC `sub` claim values
- **Azure RBAC role assignment(s)** for the service principal (optional/controlled by variables)
- (Optional but recommended) **Storage Blob Data Contributor** on the Terraform state storage account so GitHub Actions can read/write remote state using `use_azuread_auth=true`

---

## 2) Prerequisites

### Tools
- `az` CLI (logged in)
- `terraform` (>= 1.6)
- `gh` CLI (for setting repo variables + running smoke workflows)

### Permissions you need
- **Entra ID permissions** to create an App Registration + federated credentials
- **Azure RBAC permissions** to create role assignments at your chosen scope  
  If you set `enable_rbac=true` at subscription scope, you typically need permissions equivalent to **Owner** or **User Access Administrator** at that scope.

### Repo expectations (important)
Azure federated credential subjects must match **exactly**.

- If your default branch is `master`, the subject will include `refs/heads/master`.
- If your default branch is `main`, the subject will include `refs/heads/main`.

You must allow the branch you actually run workflows on.

---

## 3) Terraform layout

```text
use-cases/05-identity-bootstrap-automation/azure/
├── docs/README.md
└── terraform/
    └── oidc-bootstrap/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── terraform.tfvars   (local; do not commit)
```

---

## 4) Step-by-step: Azure UC05

### 4.1 — Create backend config (gitignored)

This repo expects Azure backend config files under `backend/` and `.gitignore` excludes `backend/*.hcl`.

Create the UC05 backend config by copying the example and filling in your storage account name:

```bash
cp backend/azure-uc05-identity-bootstrap.hcl.example backend/azure-uc05-identity-bootstrap.hcl

# Edit storage_account_name in-place (example)
sed -i 's/storage_account_name = "REPLACE_ME"/storage_account_name = "<YOUR_STORAGE_ACCOUNT_NAME>"/'   backend/azure-uc05-identity-bootstrap.hcl
```

Example backend file contents:

```hcl
resource_group_name  = "mcsa-tfstate-rg"
storage_account_name = "<YOUR_STORAGE_ACCOUNT_NAME>"
container_name       = "tfstate"
key                  = "uc05/azure/oidc-bootstrap.tfstate"
use_azuread_auth     = true
```

### 4.2 — Configure Terraform variables

Create/edit:

```text
use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap/terraform.tfvars
```

At minimum set:

```hcl
github_org  = "YOUR_GITHUB_ORG_OR_USERNAME"
github_repo = "YOUR_REPO_NAME"
```

Recommended: enable RBAC so the identity can actually manage Azure resources later:

```hcl
enable_rbac = true
```

If your environment doesn’t let Terraform auto-detect subscription/tenant, add them explicitly (recommended for reliability):

```bash
cd use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap

TID="$(az account show --query tenantId -o tsv)"
SID="$(az account show --query id -o tsv)"

echo "tenant_id = \"$TID\"" >> terraform.tfvars
echo "subscription_id = \"$SID\"" >> terraform.tfvars
```

### 4.3 — IMPORTANT: Allow correct GitHub OIDC subjects (master vs main)

Azure requires **exact** subjects and does **not** support wildcards for the `sub` claim.

If your workflows run on `master`, you must allow `refs/heads/master`. If they run on `main`, allow `refs/heads/main`.

Example that allows both (and PRs):

```hcl
# GitHub OIDC subjects to allow (Azure requires exact subjects; no wildcards)
subject_claim_patterns = [
  "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/master",
  "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main",
  "repo:YOUR_ORG/YOUR_REPO:pull_request",
]
```

> Tip: In workflow logs, `azure/login` prints the presented subject. Match it exactly.

### 4.4 — Initialize Terraform with remote backend

```bash
cd use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap

terraform fmt
terraform init -reconfigure -backend-config=../../../../../backend/azure-uc05-identity-bootstrap.hcl
terraform validate
```

### 4.5 — Plan and apply

Prefer saving a plan:

```bash
terraform plan -out tfplan
terraform apply "tfplan"
```

### 4.6 — Capture outputs (you will use these)

After apply, Terraform outputs:

- `client_id`  → GitHub Actions var `AZURE_CLIENT_ID`
- `tenant_id`  → GitHub Actions var `AZURE_TENANT_ID`
- `subscription_id` → GitHub Actions var `AZURE_SUBSCRIPTION_ID`
- `service_principal_object_id` (useful for RBAC troubleshooting)
- `allowed_subjects` (what’s permitted to authenticate)

---

## 5) Post-apply: GitHub Actions smoke test

### 5.1 — Add workflow file

Create:

```text
.github/workflows/azure-oidc-smoke.yml
```

with:

```yaml
name: azure-oidc-smoke

on:
  workflow_dispatch: {}

permissions:
  id-token: write
  contents: read

jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Prove identity
        run: |
          az account show --query '{subscription:id, tenant:tenantId, user:user.name}' -o jsonc
          echo "ARM_* environment variables should be empty when using azure/login with OIDC:"
          env | sort | rg '^ARM_' || true
```

Commit and push:

```bash
git add .github/workflows/azure-oidc-smoke.yml
git commit -m "Add Azure OIDC smoke workflow"
git push
```

### 5.2 — Set GitHub Actions variables (not secrets)

Use the Terraform outputs you just created:

```bash
gh variable set AZURE_CLIENT_ID       --repo YOUR_ORG/YOUR_REPO --body "<CLIENT_ID>"
gh variable set AZURE_TENANT_ID       --repo YOUR_ORG/YOUR_REPO --body "<TENANT_ID>"
gh variable set AZURE_SUBSCRIPTION_ID --repo YOUR_ORG/YOUR_REPO --body "<SUBSCRIPTION_ID>"

gh variable list --repo YOUR_ORG/YOUR_REPO | rg 'AZURE_(CLIENT_ID|TENANT_ID|SUBSCRIPTION_ID)'
```

### 5.3 — Run and verify the workflow

```bash
gh workflow run azure-oidc-smoke.yml --repo YOUR_ORG/YOUR_REPO
gh run list --repo YOUR_ORG/YOUR_REPO --workflow azure-oidc-smoke.yml --limit 1
gh run view <RUN_ID> --repo YOUR_ORG/YOUR_REPO --log
```

If it fails with:

```text
AADSTS700213: No matching federated identity record found for presented assertion subject ...
```

it means the workflow is presenting a `sub` claim you didn’t allow (usually because the branch is `master` vs `main`).
Add the missing subject in `subject_claim_patterns`, `terraform apply`, and rerun the workflow.

---

## 6) Required extra prerequisite for Azure remote state (data-plane access)

If you use:

```hcl
use_azuread_auth = true
```

for the azurerm backend, the identity running Terraform (including GitHub OIDC) must have **data-plane** access to the state container.

### 6.1 — Grant GitHub service principal access to the storage account

After UC05 apply, take `service_principal_object_id` and grant it **Storage Blob Data Contributor** on the storage account:

```bash
SUB="<SUBSCRIPTION_ID>"
RG="mcsa-tfstate-rg"
SA="<YOUR_STORAGE_ACCOUNT_NAME>"
SP_OBJECT_ID="<SERVICE_PRINCIPAL_OBJECT_ID>"

az account set -s "$SUB"

SA_ID="$(az storage account show -g "$RG" -n "$SA" --query id -o tsv)"

az role assignment create   --assignee-object-id "$SP_OBJECT_ID"   --assignee-principal-type ServicePrincipal   --role "Storage Blob Data Contributor"   --scope "$SA_ID"
```

> This is necessary so GitHub Actions can read/write Terraform state in Azure Storage when backend auth is keyless.

---

## 7) “Are we ready for Codex CLI to run use cases?”

Once UC05 is complete and smoke-tested for each cloud you intend to use, you’re essentially ready.

For Azure specifically, readiness means:
- ✅ Remote backend config present under `backend/azure-uc0X-*.hcl` (gitignored)
- ✅ UC05 Terraform applied (App/SP/FIC + RBAC)
- ✅ GitHub Actions variables set (AZURE_CLIENT_ID / TENANT_ID / SUBSCRIPTION_ID)
- ✅ Smoke workflow succeeds
- ✅ (If using Azure backend with Entra auth) SP has Storage Blob Data Contributor on the state storage account

At that point Codex CLI can safely run Terraform-based steps for Azure UC01–UC04 without requiring static secrets.

---

## 8) Validation snapshot

- **Date:** 2026-02-06
- **Result:** `azure-oidc-smoke` workflow completed successfully.
- **Evidence:** GitHub Actions run `azure-oidc-smoke` (run ID `21734918769`).

---

## 9) Cleanup

When you no longer need GitHub Actions OIDC access:

1) Destroy UC05 Azure stack:

```bash
cd use-cases/05-identity-bootstrap-automation/azure/terraform/oidc-bootstrap
terraform destroy
```

2) Remove GitHub variables:

```bash
gh variable delete AZURE_CLIENT_ID       --repo YOUR_ORG/YOUR_REPO --confirm
gh variable delete AZURE_TENANT_ID       --repo YOUR_ORG/YOUR_REPO --confirm
gh variable delete AZURE_SUBSCRIPTION_ID --repo YOUR_ORG/YOUR_REPO --confirm
```

3) Optionally delete role assignments (Contributor / Storage Blob Data Contributor) created for the service principal.
