# Running GitHub Actions workflows from the CLI (`gh`)

This toolkit is designed so you can run “proof” workflows (smoke tests, inventory/discovery, etc.) **without** using the GitHub web UI.

This is especially useful for Solution Architects because it’s:
- fast (all CLI)
- scriptable / repeatable
- easy to paste into tickets/runbooks

---

## Prerequisites

### 1) Install GitHub CLI (`gh`)
Ubuntu / Debian:
```bash
sudo apt update
sudo apt install -y gh
```

Verify:
```bash
gh --version
```

### 2) Authenticate to GitHub
```bash
gh auth login
gh auth status
```

> Authenticate to the GitHub account that has access to the repository.

### 3) Clone the repo
```bash
git clone https://github.com/<OWNER>/<REPO>.git
cd <REPO>
```

Optional: set a default repo for `gh` (so you can run commands from anywhere):
```bash
gh repo set-default <OWNER>/<REPO>
```

---

## Discover available workflows

List workflows:
```bash
gh workflow list
```

List workflow files:
```bash
ls -la .github/workflows
```

> Note: `gh workflow run ...` only works if the workflow has a `workflow_dispatch:` trigger.
> If you get HTTP 422, see “Common errors” below.

---

## Run workflows

### Run by workflow file path (most reliable)
```bash
gh workflow run .github/workflows/uc05-aws-smoke.yml
gh workflow run .github/workflows/uc02-aws-inventory.yml
```

### Run by workflow name (handy)
```bash
gh workflow run aws-oidc-smoke
```

---

## Monitor a workflow run

After starting a workflow, fetch the most recent run for that workflow:

```bash
gh run list --workflow uc05-aws-smoke.yml --limit 1
```

You’ll see an ID like `20862931367`. Watch it:

```bash
gh run watch <RUN_ID>
```

To watch and return a non-zero exit code on failure (great for scripts/CI):
```bash
gh run watch <RUN_ID> --exit-status
```

---

## Validate success and inspect logs

Show run details:
```bash
gh run view <RUN_ID>
```

View logs in terminal:
```bash
gh run view <RUN_ID> --log
```

### “Proof” checks (examples)

**UC05 (AWS OIDC smoke)** should show the workflow is running as an **assumed role** (OIDC), not a long-lived IAM user key:
```bash
gh run view <RUN_ID> --log | grep -E "assumed-role|github-terraform-oidc|get-caller-identity" -n || true
```

---

## Download and use artifacts (inventory outputs, reports, etc.)

Some workflows upload artifacts (e.g., UC02 AWS inventory outputs).

### Download artifacts for a run
```bash
mkdir -p /tmp/uc02
gh run download <RUN_ID> -D /tmp/uc02
```

If you see an error like “file exists”, clear the destination and retry:
```bash
rm -rf /tmp/uc02
mkdir -p /tmp/uc02
gh run download <RUN_ID> -D /tmp/uc02
```

### Find downloaded files
```bash
find /tmp/uc02 -type f \( -name "inventory.json" -o -name "SUMMARY.md" \) -print
```

### Use the outputs
View the summary:
```bash
head -n 80 /tmp/uc02/**/SUMMARY.md 2>/dev/null || head -n 80 /tmp/uc02/SUMMARY.md
```

Inspect the JSON:
```bash
jq '.' /tmp/uc02/**/inventory.json | head
```

---

## Common errors and fixes

### `HTTP 422: Workflow does not have 'workflow_dispatch' trigger`
The workflow cannot be started manually from CLI. Add this to the workflow YAML:
```yaml
on:
  workflow_dispatch:
```
Commit + push, then retry.

### Artifact download error: `file exists`
You already downloaded into the same folder. Delete it (or pick a new folder) and re-download.

### Auth/permissions errors
- `gh auth status` (confirm you’re logged in)
- Make sure you have access to the repo and Actions are enabled
- Confirm you’re operating on the correct repository (use `gh repo view`)

---

## Recommended “proof” sequence for this toolkit

1) **UC05 smoke** (OIDC auth works)
```bash
gh workflow run aws-oidc-smoke
```

2) **UC02 inventory** (discovery works + artifacts produced)
```bash
gh workflow run .github/workflows/uc02-aws-inventory.yml
```

Then:
```bash
gh run list --limit 5
```
Pick the run IDs, `gh run watch`, and download artifacts as needed.
