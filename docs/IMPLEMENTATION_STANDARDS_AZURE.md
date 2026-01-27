# Azure Implementation Standards (Use Cases UC01–UC05)

This guide codifies the standards and lessons learned from the AWS use-case implementations so Azure development stays consistent, repeatable, and low-drift.

---

## Goals
- Mirror the AWS structure, naming, and validation patterns for parity.
- Keep runs repeatable with clear cleanup steps and minimal manual drift.
- Ensure docs capture proof steps, outputs, and validation notes.

---

## Repository layout (must match AWS patterns)

Each use case lives under the shared `use-cases/` folder:
```
use-cases/<nn>-<use-case-name>/azure/
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

### Tags
Apply these tags to every resource that supports them:
- `toolkit = multicloud-sa-toolkit`
- `use_case = <nn>-<use-case-name>`
- `env = <var.env>`
- `owner = <var.owner>`
- `managed_by = terraform`

If the use case is sandbox-related, add:
- `sandbox_id = <var.sandbox_id>`

### Lessons learned
- **Changing name/prefix variables forces replacement**. Call this out in docs and cleanup.
- Ensure tags are applied uniformly across modules so cleanup can be done via tag search.

---

## Defaults and configuration

Defaults should mirror AWS intent and be cost-aware:
- **Safe defaults**: leave expensive features disabled unless explicitly enabled.
- **Explicit toggles** for modules: `enable_<feature>` in `root/variables.tf`.
- **Environment identity**: `env` defaults to `toolkit-test`, `owner` defaults to `platform-team`.
- **Backend config**: keep backend config files local and ignored by git.

### State backend
Create example backend configs in `backend/`:
- `backend/azure-uc01-landing-zone.hcl.example`
- `backend/azure-uc02-discovery.hcl.example`
- etc.

Docs must instruct users to copy the example to a local, ignored file (same name without `.example`).

---

## Authentication and CI pattern (OIDC)

Follow the AWS approach:
- UC05 establishes GitHub Actions OIDC to Azure (no long-lived secrets).
- UC02/UC03/UC04/UC01 assume that UC05 is complete.
- All workflows must use `workflow_dispatch` so they can be run via `gh`.

For docs:
- Include a smoke-proof step that shows **OIDC identity** is being used (e.g., `az account show`).
- Provide a short validation snippet that confirms the workflow is not using a static client secret.

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
- Keep cleanup steps **explicit** for resources that are hard to delete (log storage, key vaults, policy assignments).
- If manual cleanup is needed, provide the exact CLI commands to verify and remove leftovers.

---

## Documentation requirements per use case

Every Azure runbook (`azure/docs/README.md`) must include:
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

## Azure-specific open decisions (resolve before UC01)

Decide and document **scope** up front:
- Subscription-only vs Management Group scope for UC01 guardrails/logging.
- If management group scope is chosen, list required permissions and policy assignment strategy.

Do not proceed on UC01 implementation until this scope decision is documented in the UC01 runbook.

