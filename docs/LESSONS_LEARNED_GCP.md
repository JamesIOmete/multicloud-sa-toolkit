# GCP Lessons Learned (Public-Safe Excerpt)

This is a sanitized summary of validation lessons to keep GCP use cases aligned with AWS patterns without leaking environment-specific details.

## Identity + Auth
- Prefer keyless impersonation for Terraform runs. Ensure the human user has `roles/iam.serviceAccountTokenCreator` on the automation service account and that the IAM Service Account Credentials API is enabled.
- Workload Identity Pools require explicit `roles/iam.workloadIdentityPoolAdmin` on the project for the automation service account.

## Required APIs (common blockers)
- Enable upfront: IAM (`iam.googleapis.com`), IAM Credentials (`iamcredentials.googleapis.com`), Cloud Resource Manager (`cloudresourcemanager.googleapis.com`), Pub/Sub (`pubsub.googleapis.com`), Cloud Functions (`cloudfunctions.googleapis.com`), Cloud Run (`run.googleapis.com`), Eventarc (`eventarc.googleapis.com`), Cloud Build (`cloudbuild.googleapis.com`), Artifact Registry (`artifactregistry.googleapis.com`), Billing Budgets (`billingbudgets.googleapis.com`).

## Monitoring (UC03)
- Node.js 16 is deprecated in Cloud Functions; use `nodejs20`.
- Cloud Functions build may fail without Artifact Registry read/write on the **Compute Engine default service account** and Cloud Build service account. Grant:
  - `roles/artifactregistry.reader` + `roles/artifactregistry.writer` to both compute SA and Cloud Build SA.
  - `roles/storage.objectViewer` to the compute SA for `gcf-v2-sources-*` bucket access.
- Alerting: delta metrics require `aggregations.per_series_aligner` (e.g., `ALIGN_RATE`) to avoid 400 errors.
- Email channel verification is inconsistent; SMS verification was reliable. If a verified SMS channel already exists, import it into Terraform to avoid duplicate unverified channels.

## Cloud Run (UC04)
- Organization policy may block `allUsers` invoker bindings. Use **auth-required** verification and `curl` with an identity token.
- Ensure the automation SA has `roles/run.admin` to set IAM on Cloud Run services.

## Budgets (UC01/UC04)
- Budget filters expect **project number**, not project ID. Derive via `data.google_project.project.number`.
- Budget creation/update in Terraform may still fail with 403 even when gcloud impersonation succeeds. If needed, create the budget with `gcloud beta billing budgets create` and import it into Terraform, then keep future changes minimal.
- Pub/Sub budget notifications can be managed out-of-band to avoid IAM friction; document this explicitly if used.

## Local-Only Artifacts
- Keep `backend.hcl`, `*.tfplan`, and generated archives (e.g., `source.zip`) local-only.
