# Use Case 05 — GCP — Identity Bootstrap for Automation (GitHub Actions OIDC → GCP)

This document provides the runbook for establishing a trust relationship between GitHub Actions and Google Cloud Platform (GCP) using OpenID Connect (OIDC).

## 1. What this stack creates and why

This Terraform stack provisions the necessary GCP resources to allow GitHub Actions workflows to authenticate with GCP without using long-lived static service account keys. This is a security best practice.

It creates:
- **Workload Identity Pool:** A pool to manage identities for external workloads.
- **Workload Identity Pool Provider:** A provider that represents GitHub Actions as a trusted identity provider.
- **Service Account:** A dedicated service account for GitHub Actions to use.
- **IAM Bindings:** Permissions that allow the GitHub Actions identity to impersonate the service account and give the service account `Editor` permissions on the project.

## 2. Prerequisites

- Access to a GCP project with permissions to create the resources mentioned above.
- `terraform` CLI installed.
- `gcloud` CLI installed and authenticated to your GCP project.

## 3. Terraform Layout

```
use-cases/05-identity-bootstrap-automation/gcp/
└── terraform/
    └── oidc-bootstrap/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## 4. Quick Start

1.  **Configure Backend:**
    Create a `backend/gcp-uc05-identity-bootstrap.hcl.example` file (not provided in this PR), then copy it to `backend/gcp-uc05-identity-bootstrap.hcl` and populate it with your GCS backend details.

2.  **Initialize Terraform:**
    ```bash
    terraform init -backend-config=backend/gcp-uc05-identity-bootstrap.hcl
    ```

3.  **Apply Terraform:**
    You will need to provide values for `project_id`, `github_org`, and `github_repo`.

    ```bash
    export TF_VAR_project_id="your-gcp-project-id"
    export TF_VAR_github_org="your-github-org"
    export TF_VAR_github_repo="your-github-repo"

    terraform apply
    ```

## 5. Key Variables

| Variable      | Description                                | Default         |
|---------------|--------------------------------------------|-----------------|
| `project_id`  | The GCP project ID.                        | (required)      |
| `github_org`  | The GitHub organization.                   | (required)      |
| `github_repo` | The GitHub repository.                     | (required)      |
| `region`      | The GCP region for the resources.          | `us-central1`   |
| `name_prefix` | The prefix for the resource names.         | `mcsa-uc05`     |
| `env`         | The environment name.                      | `toolkit-test`  |
| `owner`       | The owner of the resources.                | `platform-team` |

## 6. Outputs

| Output                             | Description                                            |
|------------------------------------|--------------------------------------------------------|
| `workload_identity_pool_id`        | The ID of the Workload Identity Pool.                  |
| `workload_identity_pool_provider_id`| The ID of the Workload Identity Pool Provider.         |
| `service_account_email`            | The email of the created Service Account.              |
| `workload_identity_user_iam_member`| The IAM member for the Workload Identity User role.    |

## 7. Post-Apply Checklist

1.  **Verify Resources:** Check the GCP console to ensure the Workload Identity Pool, Provider, and Service Account were created.
2.  **Update GitHub Actions Workflow:** Configure your GitHub Actions workflow to use the `google-github-actions/auth` action to authenticate. You will need the Workload Identity Provider and Service Account email from the Terraform outputs.

## 8. Cleanup

Run `terraform destroy` to remove all resources created by this stack.

## 9. Validation Snapshot

- **Date:** 2026-01-21
- **Result:** Plan successfully generated. Ready for application.
- **Evidence:**
  ```
  # To be filled in after a successful `terraform apply` and
  # a successful run of a GitHub Actions workflow that
  # authenticates using the created OIDC connection.
  ```
