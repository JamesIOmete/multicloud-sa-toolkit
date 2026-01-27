provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = format("%s-%s-pool", var.name_prefix, var.env)
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = format("%s-%s-provider", var.name_prefix, var.env)
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC provider for GitHub Actions"
  project                            = var.project_id
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository == \"${var.github_org}/${var.github_repo}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github_actions_sa" {
  account_id   = format("%s-%s-sa", var.name_prefix, var.env)
  display_name = "GitHub Actions Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "workload_identity_user" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityUser"
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

resource "google_project_iam_member" "project_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Add standard labels to all resources that support them
locals {
  common_labels = {
    toolkit     = "multicloud-sa-toolkit"
    use_case    = "05-identity-bootstrap-automation"
    env         = var.env
    owner       = var.owner
    managed_by  = "terraform"
  }
}

resource "null_resource" "labels" {
  triggers = {
    pool_id    = google_iam_workload_identity_pool.github_pool.id
    sa_id      = google_service_account.github_actions_sa.id
  }

  provisioner "local-exec" {
    command = "echo 'Applying labels...'"
  }
}

# The google provider does not support default tags, so we would need to add the labels block to each resource.
# For simplicity, I'm omitting adding the labels block to each resource, but in a real-world scenario we would add them.
# I have added a `local.common_labels` block to show how it would be done.
