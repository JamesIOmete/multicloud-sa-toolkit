# Use Case 04 — GCP — Ephemeral Sandbox Factory

This document provides the runbook for deploying a short-lived, low-cost application sandbox in GCP.

## 1. What this stack creates and why

This Terraform stack provisions an ephemeral sandbox environment, which is useful for development, testing, and demos. The resources are tagged with a unique `sandbox_id` for easy identification and cleanup.

It creates:
- **VPC and Subnet:** An isolated network for the sandbox.
- **Cloud Run Service:** A "hello world" containerized application, representing a lightweight, serverless workload.
- **Billing Budget:** A budget for the project with alert thresholds to prevent cost overruns.
- **Labels:** All resources are labeled with a common set of tags, including a unique `sandbox_id`.

## 2. Prerequisites

- Access to a GCP project with permissions to create the resources mentioned above.
- Your GCP Billing Account ID.
- `terraform` CLI installed.
- `gcloud` CLI installed and authenticated to your GCP project.

## 3. Terraform Layout

```
use-cases/04-ephemeral-sandbox/gcp/
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
    Create and configure your Terraform backend file (e.g., `backend/gcp-uc04-ephemeral-sandbox.hcl`).

3.  **Initialize Terraform:**
    ```bash
    terraform init -backend-config=backend/gcp-uc04-ephemeral-sandbox.hcl
    ```

4.  **Apply Terraform:**
    You will need to provide your GCP project ID, a unique sandbox ID, and an email for budget notifications.

    ```bash
    export TF_VAR_project_id="your-gcp-project-id"
    export TF_VAR_sandbox_id="my-test-sandbox"
    export TF_VAR_notification_email="your-email@example.com"

    terraform apply
    ```

## 5. Key Variables

| Variable             | Description                                | Default         |
|----------------------|--------------------------------------------|-----------------|
| `project_id`         | The GCP project ID.                        | (required)      |
| `sandbox_id`         | A unique ID for the sandbox environment.   | (required)      |
| `notification_email` | The email address for budget notifications.| (required)      |
| `region`             | The GCP region for the resources.          | `us-central1`   |
| `name_prefix`        | The prefix for the resource names.         | `mcsa-uc04`     |
| `env`                | The environment name.                      | `toolkit-test`  |
| `owner`              | The owner of the resources.                | `platform-team` |
| `budget_amount`      | The budget amount in USD.                  | `25`            |

## 6. Outputs

| Output                | Description                        |
|-----------------------|------------------------------------|
| `vpc_name`            | The name of the created VPC.       |
| `subnet_name`         | The name of the created subnet.    |
| `cloud_run_service_url`| The URL of the Cloud Run service.  |
| `billing_budget_id`   | The ID of the billing budget.      |

## 7. Post-Apply Checklist

1.  **Verify Resources:** Check the GCP console to ensure all resources were created with the correct labels.
2.  **Access the Application:** Open the `cloud_run_service_url` in a browser to see the "Hello World" application.
3.  **Check Budget:** Verify the budget was created in the Billing section of the GCP console.

## 8. Cleanup

Run `terraform destroy` to remove all resources created by this stack. The labels and `sandbox_id` can also be used to manually identify and delete resources if needed.

## 9. Validation Snapshot

- **Date:** 2026-01-21
- **Result:** Plan successfully generated. Ready for application.
- **Evidence:** N/A (requires `terraform apply` after updating the billing account ID).
