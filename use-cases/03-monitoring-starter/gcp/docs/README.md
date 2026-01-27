# Use Case 03 — GCP — Monitoring Starter Pack

This document provides the runbook for deploying a baseline monitoring and alerting stack in GCP.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_GCP.md`
- Validation guide: `docs/VALIDATION_GCP.md`
- Lessons learned (public-safe): `docs/LESSONS_LEARNED_GCP.md`

## 1. What this stack creates and why

This Terraform stack provisions a "token workload" and corresponding monitoring to serve as a starting point for application monitoring.

It creates:
- **Pub/Sub Topic:** A messaging topic to simulate workload traffic.
- **Cloud Function:** A simple Node.js function that is triggered by messages on the Pub/Sub topic.
- **Cloud Monitoring Notification Channel:** An email-based channel to receive alerts.
- **Cloud Monitoring Alert Policies:**
    - An alert for a backlog of messages in the Pub/Sub topic.
    - An alert for any errors in the Cloud Function execution.

This provides a practical example of how to monitor a simple, event-driven application in GCP.

## 2. Prerequisites

- Access to a GCP project with permissions to create the resources mentioned above.
- `terraform` CLI installed.
- `gcloud` CLI installed and authenticated to your GCP project.

## 3. Terraform Layout

```
use-cases/03-monitoring-starter/gcp/
└── terraform/
    └── root/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── function_source/
            ├── index.js
            └── package.json
```

## 4. Quick Start

1.  **Configure Backend:**
    Create and configure your Terraform backend file (e.g., `backend/gcp-uc03-monitoring-starter.hcl`).

2.  **Initialize Terraform:**
    ```bash
    terraform init -backend-config=backend/gcp-uc03-monitoring-starter.hcl
    ```

3.  **Apply Terraform:**
    You will need to provide your GCP project ID and an email for notifications.

    ```bash
    export TF_VAR_project_id="your-gcp-project-id"
    export TF_VAR_notification_email="your-email@example.com"

    terraform apply
    ```

## 5. Key Variables

| Variable             | Description                                | Default         |
|----------------------|--------------------------------------------|-----------------|
| `project_id`         | The GCP project ID.                        | (required)      |
| `notification_email` | The email address for monitoring alerts.   | (required)      |
| `region`             | The GCP region for the resources.          | `us-central1`   |
| `name_prefix`        | The prefix for the resource names.         | `mcsa-uc03`     |
| `env`                | The environment name.                      | `toolkit-test`  |
| `owner`              | The owner of the resources.                | `platform-team` |

## 6. Outputs

| Output                | Description                         |
|-----------------------|-------------------------------------|
| `pubsub_topic_name`   | The name of the Pub/Sub topic.      |
| `cloud_function_name` | The name of the Cloud Function.     |
| `notification_channel_id`| The ID of the notification channel. |

## 7. Post-Apply Checklist & Testing

1.  **Verify Resources:** Check the GCP console to ensure the Pub/Sub topic, Cloud Function, and Monitoring resources were created.
2.  **Confirm Notification Channel:** Check your email for a confirmation from Google Cloud Monitoring to activate the notification channel.
3.  **Test the Function:**
    - Publish a message to the Pub/Sub topic:
      ```bash
      gcloud pubsub topics publish $(terraform output -raw pubsub_topic_name) --message="Hello"
      ```
    - Check the Cloud Function logs to verify it was triggered.
4.  **Test the Alerts:**
    - The alerts are configured with low thresholds, but may require manual triggering or waiting for specific conditions to fire.

## 8. Cleanup

Run `terraform destroy` to remove all resources created by this stack.

## 9. Validation Snapshot

- **Date:** 2026-01-21
- **Result:** Plan successfully generated. Ready for application.
- **Evidence:** N/A (requires `terraform apply` and manual alert testing).
