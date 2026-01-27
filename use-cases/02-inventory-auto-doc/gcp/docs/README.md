# Use Case 02 — GCP — Environment Inventory + Auto-documentation

This document provides the runbook for generating an inventory of a GCP project.

## References

- Implementation standards: `docs/IMPLEMENTATION_STANDARDS_GCP.md`
- Validation guide: `docs/VALIDATION_GCP.md`
- Lessons learned (public-safe): `docs/LESSONS_LEARNED_GCP.md`

## 1. What this script does

The `discover.sh` script uses the `gcloud` CLI to scan a GCP project and produce two artifacts:
- `inventory.json`: A detailed, machine-readable inventory of resources in JSON format.
- `SUMMARY.md`: A high-level, human-readable summary of the key resources found.

This is useful for:
- Gaining quick context on a project.
- Tracking resource changes over time.
- Onboarding new team members.

## 2. Prerequisites

- `gcloud` CLI installed and authenticated to your GCP project.
- `jq` installed to process the JSON output.
- The authenticated principal needs roles sufficient to list the discovered resources (e.g., `roles/viewer`).

## 3. How to Run

The script can be run locally or from a GitHub Actions workflow.

### Local Execution

1.  **Navigate to the script directory:**
    ```bash
    cd use-cases/02-inventory-auto-doc/gcp/scripts
    ```

2.  **Run the script with your project ID and region:**
    ```bash
    export GCP_PROJECT_ID="your-gcp-project-id"
    export GCP_REGION="your-gcp-region"

    ./discover.sh
    ```
    The output files (`inventory.json`, `SUMMARY.md`) will be created in the current directory.

### GitHub Actions

A GitHub Actions workflow can be configured to run this script and save the artifacts. (Workflow definition is not included in this use case).

## 4. Sample Output

See the `sample-output/` directory for examples of the generated files.

## 5. Validation Snapshot

- **Date:** 2026-01-21
- **Result:** Script is ready for execution.
- **Evidence:** N/A (requires execution against a live GCP project).
