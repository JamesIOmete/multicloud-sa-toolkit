# Multi-Cloud SA Toolkit (Terraform)

A practical, use-case-driven toolkit for multi-cloud Solution Architects (AWS / Azure / GCP).  
Focus: identity bootstrap for automation, environment discovery, monitoring baselines, and repeatable patterns that are easy to fork and run.

## Use cases
- **UC05 — Identity bootstrap for automation (GitHub Actions OIDC → Cloud)**
  - AWS ✅ implemented + validated
  - Azure 🧱 implemented (validation pending)
  - GCP 🧱 implemented (validation pending)

- **UC02 — Environment inventory + auto-documentation**
  - AWS ✅ implemented + validated
  - Azure 🔜
  - GCP 🔜

See: `docs/USE_CASES.md`

Cloud navigation index: `docs/CLOUDS.md`

## Repo layout
- `docs/` — prerequisites, roadmap, decisions, and use-case index
- `use-cases/` — per-use-case implementations + per-cloud docs + sample outputs
- `.github/workflows/` — CI and runnable workflows (smoke tests, inventory runs)

## Quick start
1. Read prerequisites: `docs/PREREQS.md`
2. Start with UC05 (OIDC bootstrap), then run UC02 (inventory)

## Security posture (recommended)
- CI/CD uses GitHub OIDC (no long-lived cloud keys stored in GitHub).
- Local Terraform applies use a dedicated cloud profile only when needed.

License: MIT
