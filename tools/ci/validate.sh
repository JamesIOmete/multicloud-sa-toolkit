#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TERRAFORM_ROOT="$REPO_ROOT/use-cases"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform not found in PATH"
  exit 1
fi

echo "==> Repo: $REPO_ROOT"
echo "==> Terraform root: $TERRAFORM_ROOT"
echo

if [[ ! -d "$TERRAFORM_ROOT" ]]; then
  echo "ERROR: Expected directory not found: $TERRAFORM_ROOT"
  exit 1
fi

echo "==> terraform fmt (check)"
terraform fmt -check -recursive "$TERRAFORM_ROOT"
echo

echo "==> terraform validate (backend disabled)"
# Find unique directories that contain .tf files (excluding .terraform)
mapfile -t TF_DIRS < <(
  find "$TERRAFORM_ROOT" -type f -name "*.tf" \
    -not -path "*/.terraform/*" \
    -print0 | xargs -0 -n1 dirname | sort -u
)

if [[ ${#TF_DIRS[@]} -eq 0 ]]; then
  echo "No Terraform directories found under $TERRAFORM_ROOT"
  exit 0
fi

FAIL=0
for d in "${TF_DIRS[@]}"; do
  echo "--> $d"
  (
    cd "$d"
    # validate shouldn't require credentials; avoid remote backend
    terraform init -backend=false -input=false -upgrade >/dev/null
    terraform validate -no-color
  ) || FAIL=1
  echo
done

if [[ "$FAIL" -ne 0 ]]; then
  echo "ERROR: One or more terraform validate checks failed."
  exit 1
fi

echo "✅ All terraform fmt/validate checks passed."
