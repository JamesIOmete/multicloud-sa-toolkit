# Use Case 01 — GCP — Landing Zone Lite Baseline

This document provides the runbook for deploying a minimum governance baseline to a GCP project.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_GCP.md`
- Validation guide: `docs/VALIDATION_GCP.md`
- Lessons learned (public-safe): `docs/LESSONS_LEARNED_GCP.md`

## 1. What this stack creates and why

This Terraform stack establishes a foundational governance baseline within a GCP project, ensuring adherence to best practices for security, logging, and cost management.

It creates:
-   **Organization Policies:**
    -   `constraints/gcp.resourceLocations`: Restricts resource deployment to `us-central1`.
    -   `constraints/compute.vmExternalIpAccess`: Prevents the creation of VM instances with external IP addresses.
-   **Logging:**
    -   A Cloud Storage bucket for centralized log storage.
    -   A Cloud Logging Sink to export all project logs (filtered for GCE instances and GCS buckets) to the dedicated log bucket.
-   **Cost Controls:**
    -   A Billing Budget for the project to monitor spending.
    -   A Pub/Sub topic and subscription to send budget alerts to the specified email address.

## 2. Prerequisites

-   Access to a GCP project (`mcsa-uc01-dev` or similar) with billing enabled.
-   Permissions to set Organization Policies, create Cloud Storage buckets, Cloud Logging sinks, Pub/Sub topics/subscriptions, and Billing Budgets.
-   Your GCP Billing Account ID.
-   `terraform` CLI installed.
-   `gcloud` CLI installed and authenticated, configured for service account impersonation as detailed in `docs/IMPLEMENTATION_STANDARDS_GCP.md`.

## 3. Terraform Layout

```
use-cases/01-landing-zone-lite/gcp/
└── terraform/
    └── root/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 4. Quick Start

1.  **Update `main.tf`:**
    You **must** replace the placeholder `YOUR_BILLING_ACCOUNT_ID` in `main.tf` with your actual GCP Billing Account ID.

2.  **Configure Backend:**
    Create and configure your Terraform backend file (e.g., `backend/gcp-uc01-landing-zone.hcl`).

3.  **Initialize Terraform:**
    ```bash
    terraform init -backend-config=backend/gcp-uc01-landing-zone.hcl
    ```

4.  **Apply Terraform:**
    You will need to provide your GCP project ID and an email for notifications.

    ```bash
    export TF_VAR_project_id="mcsa-uc01-dev" # Or your target project ID
    export TF_VAR_notification_email="your-email@example.com"

    terraform apply
    ```

## 5. Key Variables

| Variable             | Description                                | Default          |
|----------------------|--------------------------------------------|------------------|
| `project_id`         | The GCP project ID.                        | `mcsa-uc01-dev`  |
| `notification_email` | The email address for budget and logging notifications.| (required)       |
| `region`             | The GCP region for the resources.          | `us-central1`    |
| `name_prefix`        | The prefix for the resource names.         | `mcsa-uc01`      |
| `env`                | The environment name.                      | `toolkit-test`   |
| `owner`              | The owner of the resources.                | `platform-team`  |
| `budget_amount`      | The budget amount in USD.                  | `50`             |

## 6. Outputs

| Output                | Description                                |
|-----------------------|--------------------------------------------|
| `log_bucket_name`     | The name of the Cloud Storage bucket for logs. |
| `log_sink_name`       | The name of the Cloud Logging sink.        |
| `billing_budget_id`   | The ID of the billing budget.              |

## 7. Post-Apply Checklist

1.  **Verify Organization Policies:**
    -   In the GCP Console, navigate to IAM & Admin -> Organization Policies.
    -   Verify `Restrict resource locations` is enforced for `us-central1`.
    -   Verify `VM external IP access` is enforced (disabled).
2.  **Verify Logging:**
    -   Check the created Cloud Storage bucket in the GCP Console; logs should start appearing after some activity.
    -   Verify the Log Sink configuration in Cloud Logging.
3.  **Verify Budget:**
    -   Check the Billing section in the GCP Console to confirm the budget is active.
    -   Confirm receipt of the Pub/Sub subscription confirmation email.

## 8. Cleanup

Run `terraform destroy` to remove all resources created by this stack.

## 9. Validation Snapshot

-   **Date:** 2026-01-21
-   **Result:** Plan successfully generated. Ready for application.
-   **Evidence:** N/A (requires `terraform apply` after updating the billing account ID).
