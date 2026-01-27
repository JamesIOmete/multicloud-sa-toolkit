# GCP Validation Instructions (UC01–UC05)

These steps validate the GCP use cases and the instructions themselves. Follow in order. Stop if a use case directory or file does not exist yet.

---

## A) Prerequisites: Local setup (keyless impersonation)

Before starting, ensure your local environment is configured for keyless authentication as described in `IMPLEMENTATION_STANDARDS_GCP.md`.

1) Authenticate as your human user:
```bash
gcloud auth login
gcloud auth application-default login --no-launch-browser
```

If ADC fails with a missing scope error, re-run and consent to `cloud-platform`.

2) Set your project:
```bash
gcloud config set project <PROJECT_ID>
```

3) Set impersonation for local Terraform runs:
```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="james-terraform@<PROJECT_ID>.iam.gserviceaccount.com"
```

4) Verify impersonation:
```bash
gcloud auth print-access-token \
  --impersonate-service-account="james-terraform@<PROJECT_ID>.iam.gserviceaccount.com"
```

If this fails with `SERVICE_DISABLED`, enable the IAM Service Account Credentials API for the project and retry.

---

## B) Prerequisites: Remote state bucket

If you use a GCS backend, create a bucket first (see `IMPLEMENTATION_STANDARDS_GCP.md` for console steps).

Example backend file in each Terraform root:
```hcl
bucket = "mcsa-uc01-dev-tfstate-<unique>"
prefix = "uc05/gcp"
```

Keep `backend.hcl` local and uncommitted.

---

## C) Validation steps by use case

### Step 1: UC05 - Identity bootstrap (GCP OIDC)

1) Navigate to the directory:
```bash
cd use-cases/05-identity-bootstrap-automation/gcp/terraform/oidc-bootstrap
```

2) Create `backend.hcl` with your bucket/prefix.

3) Set variables:
```bash
export TF_VAR_project_id="<PROJECT_ID>"
export TF_VAR_github_org="<GITHUB_ORG_OR_USER>"
export TF_VAR_github_repo="<REPO_NAME>"
```

4) Initialize and apply:
```bash
terraform init -backend-config=backend.hcl
terraform apply
```
Note the `service_account_email` output.

5) Verify with a GitHub Actions smoke workflow:
- Create `.github/workflows/gcp-oidc-smoke.yml` in your repo.
- Add repo secrets:
  - `GCP_PROJECT_NUMBER`
  - `GCP_SA_EMAIL` (use `service_account_email`)

Example workflow:
```yaml
name: gcp-oidc-smoke

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  validate-gcp-auth:
    runs-on: ubuntu-latest
    steps:
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: "projects/${{ secrets.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/<POOL_ID>/providers/<PROVIDER_ID>"
          service_account: "${{ secrets.GCP_SA_EMAIL }}"

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Confirm identity
        run: gcloud auth list
```

Replace `<POOL_ID>` and `<PROVIDER_ID>` with the values created by UC05.

If apply fails with `SERVICE_DISABLED` for `iam.googleapis.com`, enable the
**Identity and Access Management (IAM) API** for the project, wait 1–2 minutes,
then re-run `terraform apply plan.tfplan`.

If apply fails with `SERVICE_DISABLED` for `cloudresourcemanager.googleapis.com`,
enable the **Cloud Resource Manager API** for the project, wait 1–2 minutes,
then re-run `terraform apply plan.tfplan`.

If apply fails with `iam.workloadIdentityPools.create` permission denied,
grant the Terraform execution identity (the impersonated service account)
`roles/iam.workloadIdentityPoolAdmin` on the project, then retry apply.

If apply fails with "Policy update access denied" while setting project IAM
bindings, grant the Terraform execution identity
`roles/resourcemanager.projectIamAdmin` on the project, wait 1–2 minutes, then
retry apply.

If apply fails with "attribute condition must reference one of the provider's claims",
ensure the workload identity pool provider sets an explicit condition like:
`assertion.repository == "<ORG>/<REPO>"`, then re-plan and apply.

If the `gcp-oidc-smoke` workflow fails with:
`must specify exactly one of "workload_identity_provider" or "credentials_json"`,
confirm the repo secrets exist and are non-empty:
- `GCP_WIF_PROVIDER`
- `GCP_SA_EMAIL`
- `GCP_PROJECT_ID`
Then re-run the workflow.

If the `gcp-oidc-smoke` workflow fails with `invalid_target`:
- Ensure `GCP_WIF_PROVIDER` is the full provider resource name using the
  **project number**, not the project ID:
  `projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/providers/<PROVIDER_ID>`
- Re-run the workflow after updating the secret.

Observed UC05 validation prerequisites (project scope):
- APIs: `iamcredentials.googleapis.com`, `iam.googleapis.com`, `cloudresourcemanager.googleapis.com`
- Roles for the impersonated service account:
  - `roles/iam.workloadIdentityPoolAdmin`
  - `roles/resourcemanager.projectIamAdmin`
  - `roles/editor` (temporary for bootstrap; tighten later)

---

### Step 2: UC01 - Landing Zone Lite

1) Navigate to the directory:
```bash
cd use-cases/01-landing-zone-lite/gcp/terraform/root
```

2) Create `backend.hcl` with a unique prefix (example: `uc01/gcp`).

3) Set variables:
```bash
export TF_VAR_project_id="<PROJECT_ID>"
export TF_VAR_billing_account_id="<BILLING_ACCOUNT_ID>"
```

4) Initialize and apply:
```bash
terraform init -backend-config=backend.hcl
terraform apply
```

5) Verification:
- GCP Console → Cloud Storage: log bucket exists.
- GCP Console → Billing → Budgets & alerts: budget exists for the project.
- GCP Console → IAM & Admin → Audit Logs (or Cloud Logging): guardrail logging enabled.

---

### Step 3: UC02 - Environment inventory

1) Navigate to the script directory:
```bash
cd use-cases/02-inventory-auto-doc/gcp/scripts
```

2) Run discovery:
```bash
./discover.sh <PROJECT_ID> <REGION> .
```

Notes:
- If prompted to enable a required API (for example `compute.googleapis.com`), answer `y` and wait for enablement.
- `jq` is required; install it before running the script if it is missing.

3) Verification:
- `inventory.json` and `SUMMARY.md` are created in the output directory.
- Contents show resources from the target project.

---

### Step 4: UC03 - Monitoring starter

1) Navigate to the directory:
```bash
cd use-cases/03-monitoring-starter/gcp/terraform/root
```

2) Create `backend.hcl` with a unique prefix (example: `uc03/gcp`).

3) Set variables:
```bash
export TF_VAR_project_id="<PROJECT_ID>"
export TF_VAR_notification_email="<EMAIL>"
```

4) Initialize and apply:
```bash
terraform init -backend-config=backend.hcl
terraform apply
```

If you see "Missing backend configuration", ensure the module has
`backend "gcs" {}` in a `versions.tf` file.

If `terraform init` fails with "Invalid character" inside alert policy filters,
fix the filter strings to use standard Terraform interpolation:
`resource.label.\"field\"=\"${resource.name}\"`.

If apply fails with `SERVICE_DISABLED` for `pubsub.googleapis.com`, enable the
**Cloud Pub/Sub API**, wait 1–2 minutes, then re-run apply.

If apply fails with `service-<PROJECT_NUMBER>@gcp-sa-cloud-run.iam.gserviceaccount.com does not exist`,
enable the **Cloud Run API** (it creates the service agent), wait 1–2 minutes,
then retry.

If apply fails while creating the Cloud Function v2, enable these APIs:
- `cloudfunctions.googleapis.com`
- `eventarc.googleapis.com`
- `run.googleapis.com`
- `cloudbuild.googleapis.com`
- `artifactregistry.googleapis.com`

If apply fails with `constraints/storage.uniformBucketLevelAccess`, ensure
the bucket sets `uniform_bucket_level_access = true`.

If Cloud Functions v2 fails due to unsupported runtime, update to a supported
runtime (for example `nodejs20`).

If alert policy creation fails due to an invalid Pub/Sub filter, ensure a
subscription exists and the filter uses
`resource.label."subscription_id"="<SUBSCRIPTION_NAME>"`.

If alert policy creation fails with
`aggregation.perSeriesAligner` missing on a DELTA metric, add:
```
aggregations {
  alignment_period   = "60s"
  per_series_aligner = "ALIGN_RATE"
}
```

If Cloud Functions v2 build fails with a missing permission on the build
service account, grant the Cloud Build service account
`roles/artifactregistry.writer` on the project, then retry apply.

If the build still fails with a missing permission on the build service account,
grant the Cloud Build service account `roles/storage.admin` on the project,
wait 1–2 minutes, then retry apply.

If the build still fails, inspect the Cloud Build error for the exact missing
permission and add it explicitly. Use:
```bash
gcloud builds describe <BUILD_ID> --region us-central1 --project <PROJECT_ID>
```
The `BUILD_ID` is in the Terraform error log URL.

If the build output indicates access denied to the `gcf-v2-sources-<PROJECT_NUMBER>-<REGION>`
bucket, grant `roles/storage.objectViewer` to the compute default service account:
`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`.

If `gcloud builds describe` is not enough, fetch the build logs:
```bash
gcloud builds log <BUILD_ID> --region us-central1 --project <PROJECT_ID>
```

If build logs show `artifactregistry.repositories.downloadArtifacts` denied,
grant `roles/artifactregistry.reader` to both:
- Cloud Build service account: `<PROJECT_NUMBER>@cloudbuild.gserviceaccount.com`
- Compute default service account: `<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`
Then retry.

If build logs show `artifactregistry.repositories.uploadArtifacts` denied,
grant `roles/artifactregistry.writer` to the compute default service account:
`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`, then retry.

5) Verification:
- Confirm SMS notification channel verification code and complete validation.
- Trigger the test workload per the runbook.
- Check alerting/logs in Cloud Monitoring and Cloud Logging.

If you need to check channel status via CLI, use:
```bash
gcloud beta monitoring channels list \
  --filter="displayName=\"SMS Notification\"" \
  --format="value(name)"

gcloud beta monitoring channels describe <CHANNEL_NAME> \
  --format="yaml(name,verificationStatus,labels)"
```

If you already have a VERIFIED SMS channel, import it and reattach policies:
```bash
terraform state rm google_monitoring_notification_channel.sms
terraform import google_monitoring_notification_channel.sms <CHANNEL_NAME>
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

If Terraform fails with `invalid_grant` or `invalid_rapt`, re-authenticate:
```bash
gcloud auth login --no-launch-browser
gcloud auth application-default login --no-launch-browser
```

If the email verification never arrives, recreate the channel by deleting the
alert policies and channel, then re-applying:
```bash
gcloud monitoring policies list --project <PROJECT_ID> \
  --format="value(name)"
gcloud monitoring policies delete <POLICY_ID> --project <PROJECT_ID>
gcloud beta monitoring channels delete <CHANNEL_NAME>
```

---

### Step 5: UC04 - Ephemeral sandbox

1) Navigate to the directory:
```bash
cd use-cases/04-ephemeral-sandbox/gcp/terraform/root
```

2) Create `backend.hcl` with a unique prefix (example: `uc04/gcp`).

3) Set variables:
```bash
export TF_VAR_project_id="<PROJECT_ID>"
export TF_VAR_billing_account_id="<BILLING_ACCOUNT_ID>"
export TF_VAR_sandbox_id="sbx-$(date +%s)"
export TF_VAR_impersonate_service_account="james-terraform@<PROJECT_ID>.iam.gserviceaccount.com"
```

4) Initialize and apply:
```bash
terraform init -backend-config=backend.hcl
terraform apply
```

If `terraform plan` fails with "Unsupported argument" for `labels` on
`google_compute_network` or `google_compute_subnetwork`, remove the `labels`
field (these resources do not support labels in this provider version).

5) Verification:
- Cloud Run is private by default (org policy may block `allUsers`). Validate with an identity token:
  ```bash
  TOKEN=$(gcloud auth print-identity-token)
  curl -H "Authorization: Bearer ${TOKEN}" <CLOUD_RUN_URL>
  ```
- GCP Console → VPC network: VPC/subnet created with `sandbox_id` label.
- GCP Console → Billing → Budgets & alerts: sandbox budget exists.

Notes:
- UC04 budgets do not configure Pub/Sub notifications by default; set up
  notification delivery separately if required.

If apply fails with `SERVICE_DISABLED` for `billingbudgets.googleapis.com`,
enable the **Cloud Billing Budget API**, wait 1–2 minutes, then retry.

If apply fails with `run.services.setIamPolicy` denied, grant the Terraform
execution identity `roles/run.admin` on the project, then retry.

If apply fails with "users do not belong to a permitted customer" when setting
Cloud Run IAM, remove the public `allUsers` binding (org policy blocks it) or
use an org-approved principal.

If budget creation fails with `The caller does not have permission`, grant the
Terraform execution identity `roles/billing.costsManager` on the billing account,
then retry.

If budget creation still fails, pass the raw billing account ID (no prefix).
The config strips `billingAccounts/` and sends the ID only.

If budget creation still fails after `billing.costsManager`, grant
`roles/billing.admin` on the billing account to the Terraform execution identity.

If budget creation still fails in Terraform but succeeds with `gcloud`, create
the budget via `gcloud` and import it:
```bash
gcloud beta billing budgets create \
  --billing-account=<BILLING_ACCOUNT_ID> \
  --display-name="<BUDGET_NAME>" \
  --budget-amount=<AMOUNT>USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0 \
  --filter-projects=projects/<PROJECT_ID> \
  --impersonate-service-account=<SA_EMAIL>

gcloud beta billing budgets list \
  --billing-account=<BILLING_ACCOUNT_ID> \
  --format="value(name,displayName)"

terraform import google_billing_budget.budget billingAccounts/<BILLING_ACCOUNT_ID>/budgets/<BUDGET_ID>
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

If Terraform still fails when updating the budget with notifications, leave
`all_updates_rule` unset and manage budget notifications outside Terraform.

If Terraform still fails to update the imported budget, force it to use the
impersonated access token (no double-impersonation):
```bash
unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
unset TF_VAR_impersonate_service_account
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token \
  --impersonate-service-account=<SA_EMAIL>)
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

Note: budgets prefer project numbers; use `projects/<PROJECT_NUMBER>`.

If UC01 destroy reports a cycle involving `google_logging_project_sink` and
`google_storage_bucket_iam_member`, remove the `postcondition` from the sink
and re-plan.

If UC01 plan fails with `google_organization_policy` missing `org_id`, switch
to `google_project_organization_policy` for project-scoped constraints.

If destroy fails with Cloud Run deletion protection, set
`deletion_protection = false` on the Cloud Run service, apply, then re-run
the destroy plan.

If you force Terraform to use `GOOGLE_OAUTH_ACCESS_TOKEN`, unset
`GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` and `TF_VAR_impersonate_service_account`
to avoid double-impersonation errors (`iam.serviceAccounts.getAccessToken`).

---

## D) Cleanup (after validation)

Run `terraform destroy` in each use case directory after validation is complete. For UC04, use a destroy plan if the runbook requires it.

Record successful cleanup steps as you go.

### UC04 cleanup notes (successful)
- Set `deletion_protection = false` on Cloud Run, apply, then destroy plan.
- Destroyed: Cloud Run service, VPC, subnet, budget, Pub/Sub topic.

### UC03 cleanup notes (successful)
- Destroyed: Cloud Function, Pub/Sub topic/subscription, alert policies, SMS channel, source bucket + object, and IAM bindings for build/service accounts.

### UC01 cleanup notes (verified)
- No UC01 logging sinks, org policies, or budgets remaining.
- Only the TF state bucket (`mcsa-uc01-dev-tfstate-james`) remains, as expected.

### UC05 cleanup notes (successful)
- Destroyed: workload identity pool/provider, GitHub Actions service account, IAM bindings, and helper null_resource.

---

## E) Local validation notes (use placeholders)

Record the latest UC05 outputs here using placeholders (do not commit real IDs):
```text
service_account_email = "mcsa-uc05-<env>-sa@<project-id>.iam.gserviceaccount.com"
workload_identity_pool_id = "projects/<project-id>/locations/global/workloadIdentityPools/mcsa-uc05-<env>-pool"
workload_identity_pool_provider_id = "projects/<project-id>/locations/global/workloadIdentityPools/mcsa-uc05-<env>-pool/providers/mcsa-uc05-<env>-provider"
workload_identity_user_iam_member = "principalSet://iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/mcsa-uc05-<env>-pool/attribute.repository/<org>/<repo>"
```
