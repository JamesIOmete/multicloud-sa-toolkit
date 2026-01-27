# GCP Implementation Standards (Use Cases UC01–UC05)

This guide codifies the standards and lessons learned from the AWS use-case implementations so GCP development stays consistent, repeatable, and low-drift.

---

## Goals
- Mirror the AWS structure, naming, and validation patterns for parity.
- Keep runs repeatable with clear cleanup steps and minimal manual drift.
- Ensure docs capture proof steps, outputs, and validation notes.

---

## Repository layout (must match AWS patterns)

Each use case lives under the shared `use-cases/` folder:
```
use-cases/<nn>-<use-case-name>/gcp/
  docs/README.md             # runbook (primary doc entry)
  terraform/
    root/                    # composition layer (feature toggles)
    modules/                 # reusable building blocks
  sample-output/             # sanitized outputs for UC02 (if applicable)
  scripts/                   # discovery scripts for UC02 (if applicable)
```

When a use case is multi-cloud, the top-level `use-cases/<nn>-.../README.md` should point to the per-cloud docs.

---

## Naming and tagging (non-negotiable)

### Name prefix
- Default `name_prefix` should follow: `mcsa-uc<nn>-<env>`
- Example: `mcsa-uc03-toolkit-test`

### Labels / tags
Apply these labels to every resource that supports them:
- `toolkit = multicloud-sa-toolkit`
- `use_case = <nn>-<use-case-name>`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`

If the use case is sandbox-related, add:
- `sandbox_id = <var.sandbox_id>`

### Lessons learned
- **Changing name/prefix variables forces replacement**. Call this out in docs and cleanup.
- Ensure labels are applied uniformly across modules so cleanup can be done via label search.

---

## Defaults and configuration

Defaults should mirror AWS intent and be cost-aware:
- **Safe defaults**: leave expensive features disabled unless explicitly enabled.
- **Explicit toggles** for modules: `enable_<feature>` in `root/variables.tf`.
- **Environment identity**: `env` defaults to `toolkit-test`, `owner` defaults to `platform-team`.
- **Backend config**: keep backend config files local and ignored by git.

### State backend
Create example backend configs in `backend/`:
- `backend/gcp-uc01-landing-zone.hcl.example`
- `backend/gcp-uc02-discovery.hcl.example`
- etc.

Docs must instruct users to copy the example to a local, ignored file (same name without `.example`).

---

## Required pre-setup (assumed complete before any UC work)

These steps mirror the AWS approach (user auth + role/impersonation) and must be done once up front.

### 1) Create a dev project
- Create a dedicated project (example: `mcsa-uc01-dev`) with billing enabled.
- Use a dev/sandbox project; avoid prod or shared control-plane projects.

### 1a) Create a GCS state bucket (if using remote state)
- Go to **Cloud Storage → Buckets → Create**.
- Bucket name: `mcsa-<env>-tfstate-<unique>` (must be globally unique).
- Location type: **Region** (pick the same region you use for Terraform).
- Default storage class: **Standard**.
- Public access: **Prevent public access**.
- Leave defaults for access control; do not enable object versioning unless required.

This bucket is a prerequisite for any `backend.hcl` that points to GCS.

### 2) Create a Terraform service account
- Create service account: `james-terraform`
- Purpose: local Terraform execution for toolkit use cases.
- Grant **project-level roles** needed for the target UC (start broad for validation, tighten later).

Minimum roles observed for UC05 validation (project scope):
- `roles/iam.workloadIdentityPoolAdmin`
- `roles/resourcemanager.projectIamAdmin`
- `roles/editor` (temporary for bootstrap; tighten later)

Required APIs observed for UC05 validation:
- **IAM Service Account Credentials API** (`iamcredentials.googleapis.com`)
- **Identity and Access Management (IAM) API** (`iam.googleapis.com`)
- **Cloud Resource Manager API** (`cloudresourcemanager.googleapis.com`)

### 3) Grant the human user impersonation rights
- Add your normal user as a **principal on the service account**.
- Role: `Service Account Token Creator` (`roles/iam.serviceAccountTokenCreator`).
- This is required for keyless impersonation from the CLI/TF provider.

### 4) Local auth model (keyless, recommended)
- Authenticate locally as your normal user.
- Use impersonation for Terraform runs via:
  - Provider: `impersonate_service_account = "james-terraform@<project-id>.iam.gserviceaccount.com"`, or
  - Env var: `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`.

Do not create service account JSON keys unless explicitly required for a specific workflow.

### Quick validation checklist (local)
- `gcloud auth list` shows your normal user as ACTIVE.
- `gcloud config get-value project` returns the dev project ID.
- Impersonation works (token returned):
  ```bash
  gcloud auth print-access-token \
    --impersonate-service-account=james-terraform@<project-id>.iam.gserviceaccount.com
  ```
- Optional proof call:
  ```bash
  gcloud projects describe <project-id> \
    --impersonate-service-account=james-terraform@<project-id>.iam.gserviceaccount.com
  ```

---

## Authentication and CI pattern (OIDC)

Follow the AWS approach:
- UC05 establishes GitHub Actions OIDC to GCP (no long-lived keys).
- UC02/UC03/UC04/UC01 assume that UC05 is complete.
- All workflows must use `workflow_dispatch` so they can be run via `gh`.

For docs:
- Include a smoke-proof step that shows **OIDC identity** is being used (e.g., `gcloud auth list`).
- Provide a short validation snippet that confirms the workflow is not using a static key.

---

## Testing and validation

Do not add automated tests unless requested. Instead, provide:
- **Proof run** steps in the runbook (per use case).
- A **validation snapshot** with date and expected output signals.
- Instructions for running the GitHub Actions workflow from CLI (`gh workflow run`).

### Standard proof pattern
1. Trigger workflow via `gh` or the Actions UI.
2. Watch run and capture logs.
3. Download artifacts (e.g., `inventory.json`, `SUMMARY.md`).
4. Record a validation note with date and evidence.

---

## Cleanup and repeatability

Each runbook must include:
- A **destroy workflow** (terraform destroy or plan/apply destroy).
- Manual cleanup steps for cloud services with retention or delayed deletion.
- Guidance on what is safe to change in place vs what forces replacement.

### Lessons learned to carry over
- Keep cleanup steps **explicit** for resources that are hard to delete (log buckets, keys, org policies).
- If manual cleanup is needed, provide the exact CLI commands to verify and remove leftovers.

---

## Documentation requirements per use case

Every GCP runbook (`gcp/docs/README.md`) must include:
- What the stack creates and why.
- Prerequisites (UC05, permissions, backend config).
- Terraform layout diagram.
- Quick start with explicit env vars and commands.
- Key variables table.
- Outputs list.
- Post-apply checklist.
- Notes/troubleshooting.
- Cleanup steps and repeatability references (`docs/CLEANUP.md`).
- Validation snapshot with date.

UC02 additionally requires:
- `scripts/` for discovery
- `sample-output/` with sanitized `SUMMARY.sample.md` and `inventory.sample.json`

---

## GCP-specific open decisions (resolve before UC01)

Decide and document **scope** up front:
- Org/Folder vs Project-only scope for UC01 guardrails/logging.
- If org-level scope is chosen, list required org permissions and constraints.

Do not proceed on UC01 implementation until this scope decision is documented in the UC01 runbook.
