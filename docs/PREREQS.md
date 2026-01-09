# Cloud prerequisites (to be filled)

## AWS
- Auth method: SSO or access keys locally; GitHub Actions via OIDC role

## Azure
- `az login`, subscription selected; GitHub Actions via federated creds

## GCP
- `gcloud auth application-default login`; GitHub Actions via Workload Identity Federation

---

## Recommended local AWS auth (for Terraform applies)

For local Terraform operations that use an S3 backend, use an AWS CLI profile backed by ~/.aws/credentials:

- Create or reuse a profile (example): james-terraform
- Confirm it is key-based:

```bash
aws configure list --profile james-terraform
```

Look for shared-credentials-file entries for access_key and secret_key.

Run Terraform with:

```bash
export AWS_PROFILE=james-terraform
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export AWS_SDK_LOAD_CONFIG=1
export AWS_EC2_METADATA_DISABLED=true
```

CI (GitHub Actions) should use OIDC (no long-lived keys).
