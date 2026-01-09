# Multi-Cloud SA Toolkit (Terraform)

A practical, use-case-driven toolkit for multi-cloud Solution Architects (AWS, Azure, GCP).
Focus areas: automation bootstrap, environment discovery, monitoring baselines, and repeatable patterns that are easy to fork and run.

## Use cases
- UC05 - Identity bootstrap for automation (GitHub Actions OIDC to cloud)
	- AWS: implemented and validated
	- Azure: implementation present, validation pending
	- GCP: implementation present, validation pending
- UC02 - Environment inventory and auto-documentation
	- AWS: implemented and validated
	- Azure: planned
	- GCP: planned

See docs/USE_CASES.md for the full list.

## Repo layout
- docs — decisions, prerequisites, roadmap, and use-case index
- use-cases/<number>-<name> — per-use-case implementations and documentation
- backend — backend configuration templates (some files are local-only)
- .github/workflows — CI workflows and runnable automation

## Quick start
1. Review prerequisites in docs/PREREQS.md.
2. Start with UC05 (OIDC bootstrap) to create the GitHub Actions trust.
3. Run UC02 (inventory) once OIDC access is in place.

## Security posture (recommended)
- CI and automation use GitHub OIDC, avoiding long-lived cloud keys in GitHub.
- Local Terraform applies use dedicated cloud profiles only when required for IAM or backend changes.

License: MIT

