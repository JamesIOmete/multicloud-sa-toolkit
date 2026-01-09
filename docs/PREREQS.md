# Prerequisites

This repo is a **use-case-driven Terraform toolkit** for multi-cloud Solution Architect work (AWS / Azure / GCP).

Examples use **us-west-2**; change regions as needed.

## Required tooling (local dev)
- **Terraform** (v1.6+ recommended) and the relevant providers
- **Git**
- **GitHub CLI (`gh`)** (for repo + Actions workflow checks)
- Cloud CLIs (as you implement each cloud):
  - **AWS CLI v2** (`aws`)
  - **Azure CLI** (`az`) — for Azure use cases
  - **Google Cloud CLI** (`gcloud`) — for GCP use cases
- Optional but handy:
  - `jq` (inspect JSON outputs)
  - `make` (if you use the repo Makefile)
  - `python3` (for output sanitization helpers, if/when added)

Quick checks:
```bash
terraform version
gh auth status
aws --version
```

## Git hygiene (strongly recommended)
Do **not** commit:
- `terraform.tfstate*`
- `.terraform/`
- local backend config files that contain real bucket names (example: `backend/*.hcl`)

## Authentication model (recommended)
Use **different auth modes** for CI vs local work:

### CI (GitHub Actions)
- Use **GitHub Actions OIDC** to assume a cloud role.
- Do **not** store long-lived cloud access keys as GitHub secrets.

### Local Terraform apply (when you must run Terraform locally)
- Use a dedicated CLI profile backed by `~/.aws/credentials` for AWS.
- Set region + disable IMDS to avoid confusing credential resolution:

```bash
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true

aws sts get-caller-identity
```

## Remote state prerequisites (Terraform backends)
Some stacks use a remote backend (AWS S3, etc.). In those cases:

- The backend storage **must already exist** (e.g., S3 bucket for AWS backends).
- Each stack should use a **unique state key** (path) to avoid collisions.
- Keep backend config files **local** when they contain real resource names.

