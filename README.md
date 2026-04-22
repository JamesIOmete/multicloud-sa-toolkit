# Multi-Cloud SA Toolkit (Terraform)

A practical, use-case-driven toolkit for multi-cloud Solution Architects (AWS / Azure / GCP).  
Focus: identity bootstrap for automation, environment discovery, monitoring baselines, and repeatable patterns that are easy to fork and run.

## Use cases
- **UC01 — Landing Zone Lite baseline (guardrails + logging + cost controls)**
  - AWS ✅ implemented + validated
  - Azure ✅ implemented + validated
  - GCP ✅ implemented + validated

- **UC02 — Environment inventory + auto-documentation**
  - AWS ✅ implemented + validated
  - Azure ✅ implemented + validated
  - GCP ✅ implemented + validated

- **UC03 — Monitoring starter (token workloads + CloudWatch alerts)**
  - AWS ✅ implemented + validated
  - Azure ✅ implemented + validated
  - GCP ✅ implemented + validated

- **UC04 — Ephemeral sandbox factory (Fargate + cost guardrails)**
  - AWS ✅ implemented + validated
  - Azure ✅ implemented + validated
  - GCP ✅ implemented + validated

- **UC05 — Identity bootstrap for automation (GitHub Actions OIDC → Cloud)**
  - AWS ✅ implemented + validated
  - Azure ✅ implemented + validated
  - GCP ✅ implemented + validated

See: `docs/USE_CASES.md`
Validation guide: `docs/VALIDATION_GCP.md`
Implementation standards: `docs/IMPLEMENTATION_STANDARDS_GCP.md`, `docs/IMPLEMENTATION_STANDARDS_AZURE.md`
Lessons learned (public-safe): `docs/LESSONS_LEARNED_GCP.md`

Cloud navigation index: `docs/CLOUDS.md`

## Artifact bundles (new)
UC02 can generate a portable artifact bundle under `out/artifacts/`:
- normalized `inventory.json` (stable schema across clouds)
- `SUMMARY.md`, `SCORECARD.md`, and `diagram.mmd` (Mermaid)

Docs: `docs/artifacts/README.md`

## Repo layout
- `docs/` — prerequisites, roadmap, decisions, and use-case index
- `use-cases/` — per-use-case implementations + per-cloud docs + sample outputs
- `.github/workflows/` — CI and runnable workflows (smoke tests, inventory runs)

## Quick start
1. Read prerequisites: `docs/PREREQS.md`
2. Bootstrap GitHub Actions trust (UC05) so automation can run keyless.
3. Apply the landing zone baseline (UC01) to enable guardrails, logging, and cost alerts.
4. Capture current-state inventory (UC02) before further changes.
5. Stand up the monitoring starter pack (UC03) or ephemeral sandbox (UC04) as needed for workload validation.

## Security posture (recommended)
- CI/CD uses GitHub OIDC (no long-lived cloud keys stored in GitHub).
- Local Terraform applies use a dedicated cloud profile only when needed.

## Related projects

- **[tf-plan-ai-reviewer](https://github.com/JamesIOmete/tf-plan-ai-reviewer)** — AI-powered Terraform plan reviewer built on this toolkit's patterns. Runs `terraform plan -json` through an LLM and posts a PASS/WARN/BLOCK verdict as a GitHub PR comment. The fixture data for that project is drawn from this toolkit's UC06 plan output.

License: MIT
