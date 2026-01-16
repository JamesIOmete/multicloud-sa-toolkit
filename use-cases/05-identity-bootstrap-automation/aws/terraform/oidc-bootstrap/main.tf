# TODO:
# - aws_iam_openid_connect_provider for token.actions.githubusercontent.com
# - aws_iam_role with trust policy restricted to repo/branch/environment
# - attach least-privilege policies (scoped to Terraform needs)

provider "aws" {
  region = var.aws_region
}

locals {
  repo_full = "${var.github_org}/${var.github_repo}"

  # Sensible defaults if user doesn't provide patterns:
  # - allow main branch
  # - allow PR workflows (common for CI)
  default_subjects = [
    "repo:${local.repo_full}:ref:refs/heads/main",
    "repo:${local.repo_full}:pull_request",
  ]

  subjects = length(var.subject_claim_patterns) > 0 ? var.subject_claim_patterns : local.default_subjects
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub's OIDC thumbprint can change; AWS accepts the root CA thumbprint.
  # This value is commonly used for token.actions.githubusercontent.com.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Audience must be sts.amazonaws.com for AWS
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to your repo and the refs/environments you allow
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = length(trimspace(var.inline_policy_json)) > 0 ? 1 : 0
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.github_actions.id
  policy = var.inline_policy_json
}
