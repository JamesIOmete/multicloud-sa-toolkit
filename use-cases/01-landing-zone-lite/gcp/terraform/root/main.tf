provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = {
    toolkit     = "multicloud-sa-toolkit"
    use_case    = "01-landing-zone-lite"
    env         = var.env
    owner       = var.owner
    managed_by  = "terraform"
  }
  billing_account = replace(var.billing_account_id, "billingAccounts/", "")
}

# --- 1. Guardrails (Organization Policies - Project Level) ---

resource "google_project_organization_policy" "restrict_resource_locations" {
  project    = var.project_id
  constraint = "constraints/gcp.resourceLocations"
  list_policy {
    allow {
      values = [
        "in:us-central1-locations",
      ]
    }
  }
  depends_on = [data.google_project.project]
}

resource "google_project_organization_policy" "disable_external_ip_addresses" {
  project    = var.project_id
  constraint = "constraints/compute.vmExternalIpAccess"
  boolean_policy {
    enforced = true
  }
  depends_on = [data.google_project.project]
}

data "google_project" "project" {
  project_id = var.project_id
}

# --- 2. Logging ---

resource "google_storage_bucket" "log_bucket" {
  name          = format("%s-%s-logs-%s", var.name_prefix, var.env, var.project_id)
  location      = var.region
  force_destroy = true
  labels        = local.common_labels
}

resource "google_logging_project_sink" "log_sink" {
  name        = format("%s-%s-sink", var.name_prefix, var.env)
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.log_bucket.name}"
  filter      = "resource.type=\"gce_instance\" OR resource.type=\"gcs_bucket\""
}

resource "google_storage_bucket_iam_member" "log_bucket_writer" {
  bucket = google_storage_bucket.log_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.log_sink.writer_identity
}

# --- 3. Cost Controls ---

resource "google_billing_budget" "budget" {
  billing_account = local.billing_account
  display_name    = format("%s-%s-budget", var.name_prefix, var.env)

  budget_filter {
    projects = ["projects/${data.google_project.project.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
}
