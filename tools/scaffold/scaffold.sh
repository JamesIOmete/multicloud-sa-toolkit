#!/usr/bin/env bash
set -euo pipefail

#!/usr/bin/env bash
set -euo pipefail


cat > init-multicloud-oidc-repo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${1:-}"
if [[ -z "$REPO_NAME" ]]; then
  echo "Usage: $0 <repo-name>"
  exit 1
fi

CREATE_REMOTE="${CREATE_REMOTE:-0}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1"
    exit 1
  }
}

need git

if [[ -d "$REPO_NAME" ]]; then
  echo "Directory already exists: $REPO_NAME"
  exit 1
fi

mkdir -p "$REPO_NAME"
cd "$REPO_NAME"
git init

# ---------- folders ----------
mkdir -p \
  .github/workflows \
  docs \
  scripts \
  stacks/aws/oidc-bootstrap \
  stacks/azure/oidc-bootstrap \
  stacks/gcp/oidc-bootstrap

# ---------- common files ----------
cat > .gitignore <<'GITIGNORE'
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
*.tfvars.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# IDE / OS
.vscode/
.idea/
.DS_Store
GITIGNORE

cat > .editorconfig <<'EDITORCONFIG'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
EDITORCONFIG

cat > LICENSE <<'LICENSE'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE

cat > README.md <<'README'
# Multi-Cloud GitHub OIDC Bootstrap (Terraform)

Terraform stacks to enable **keyless CI/CD** from GitHub Actions to:
- **AWS** (IAM role + OIDC provider trust)
- **Azure** (Entra app/SP + federated credentials)
- **GCP** (Workload Identity Federation + service account)

## Repo layout
- `stacks/aws/oidc-bootstrap`
- `stacks/azure/oidc-bootstrap`
- `stacks/gcp/oidc-bootstrap`

## Quick start (per stack)
1. `cd stacks/<cloud>/oidc-bootstrap`
2. `terraform init`
3. `terraform plan`
4. `terraform apply`

> Note: each cloud stack will be implemented to accept a consistent set of variables:
> org, repo, optional environment/branch refs, and least-privilege role assignment patterns.

## CI
GitHub Actions runs:
- `terraform fmt -check -recursive`
- `terraform validate` per stack (backend disabled in CI)

README

cat > Makefile <<'MAKEFILE'
SHELL := /usr/bin/env bash

.PHONY: fmt validate

fmt:
	terraform fmt -recursive

validate:
	./scripts/ci_validate.sh
MAKEFILE

# ---------- CI validate script ----------
cat > scripts/ci_validate.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find "$ROOT/stacks" -mindepth 2 -maxdepth 2 -type d | while read -r dir; do
  if ls "$dir"/*.tf >/dev/null 2>&1; then
    echo "==> Validating: ${dir#$ROOT/}"
    (cd "$dir" && terraform init -backend=false -input=false >/dev/null && terraform validate)
  fi
done
SH
chmod +x scripts/ci_validate.sh

# ---------- GitHub Actions ----------
cat > .github/workflows/ci.yml <<'YML'
name: ci

on:
  pull_request:
  push:
    branches: [ "main" ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform fmt (check)
        run: terraform fmt -check -recursive

      - name: Terraform validate
        run: ./scripts/ci_validate.sh
YML

# ---------- stack skeletons ----------
# AWS
cat > stacks/aws/oidc-bootstrap/versions.tf <<'TF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
TF

cat > stacks/aws/oidc-bootstrap/variables.tf <<'TF'
variable "aws_region" {
  type        = string
  description = "AWS region to use for IAM (global-ish, but provider needs a region)."
  default     = "us-east-1"
}
TF

cat > stacks/aws/oidc-bootstrap/main.tf <<'TF'
provider "aws" {
  region = var.aws_region
}

# TODO:
# - aws_iam_openid_connect_provider for token.actions.githubusercontent.com
# - aws_iam_role with trust policy restricted to repo/branch/environment
# - attach least-privilege policies (scoped to Terraform needs)
TF

cat > stacks/aws/oidc-bootstrap/outputs.tf <<'TF'
# TODO: output role_arn and audience/subject patterns
TF

# Azure
cat > stacks/azure/oidc-bootstrap/versions.tf <<'TF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0"
    }
  }
}
TF

cat > stacks/azure/oidc-bootstrap/main.tf <<'TF'
provider "azurerm" {
  features {}
}

provider "azuread" {}

# TODO:
# - Entra app registration + service principal
# - federated identity credential for GitHub OIDC
# - role assignments at RG/subscription scope (least privilege)
TF

cat > stacks/azure/oidc-bootstrap/variables.tf <<'TF'
# TODO: tenant_id, subscription_id (optional if using az cli), github org/repo, scope targets
TF

cat > stacks/azure/oidc-bootstrap/outputs.tf <<'TF'
# TODO: client_id, tenant_id, subscription_id, and recommended GH secrets/vars
TF

# GCP
cat > stacks/gcp/oidc-bootstrap/versions.tf <<'TF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}
TF

cat > stacks/gcp/oidc-bootstrap/main.tf <<'TF'
# TODO: google provider config (project/region)
# TODO:
# - Workload Identity Pool + Provider for GitHub
# - Service account + iam bindings for workload identity principalSet
TF

cat > stacks/gcp/oidc-bootstrap/variables.tf <<'TF'
# TODO: project_id, region, github org/repo
TF

cat > stacks/gcp/oidc-bootstrap/outputs.tf <<'TF'
# TODO: workload_identity_provider, service_account_email, recommended GH vars
TF

# Docs placeholders
cat > docs/prereqs.md <<'MD'
# Cloud prerequisites (to be filled)

## AWS
- Auth method: SSO or access keys locally; GitHub Actions via OIDC role

## Azure
- `az login`, subscription selected; GitHub Actions via federated creds

## GCP
- `gcloud auth application-default login`; GitHub Actions via Workload Identity Federation
MD

git add .
git commit -m "Initial scaffold for multi-cloud GitHub OIDC bootstrap"

# ---------- optional remote repo ----------
if [[ "$CREATE_REMOTE" == "1" ]]; then
  need gh
  echo "Creating GitHub repo and pushing (public)..."
  gh auth status >/dev/null
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
  echo "Done."
else
  echo "Local repo created. To create remote later:"
  echo "  gh repo create \"$REPO_NAME\" --public --source=. --remote=origin --push"
fi
EOF

chmod +x init-multicloud-oidc-repo.sh
./init-multicloud-oidc-repo.sh "${1:-multicloud-sa-toolkit}"
