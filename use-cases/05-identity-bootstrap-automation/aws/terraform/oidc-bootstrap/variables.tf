variable "aws_region" {
  type        = string
  description = "AWS region to use for IAM (provider requires a region)."
  default     = "us-west-2"
}

variable "github_org" {
  type        = string
  description = "GitHub org or username that owns the repo (e.g., jward448)."
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name (e.g., multicloud-sa-toolkit)."
}

variable "subject_claim_patterns" {
  type        = list(string)
  description = <<EOT
List of allowed 'sub' claim patterns for GitHub OIDC.
Examples:
- repo:ORG/REPO:ref:refs/heads/main
- repo:ORG/REPO:pull_request
- repo:ORG/REPO:environment:prod
EOT

  default = []
}

variable "role_name" {
  type        = string
  description = "Name for the IAM role GitHub Actions will assume."
  default     = "github-terraform-oidc"
}

variable "role_description" {
  type        = string
  description = "Description for the IAM role."
  default     = "GitHub Actions OIDC role for Terraform"
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "Optional AWS managed policy ARNs to attach (demo-friendly)."
  default     = []
}

variable "inline_policy_json" {
  type        = string
  description = "Optional inline policy JSON (least privilege). Leave empty to skip."
  default     = ""
}
