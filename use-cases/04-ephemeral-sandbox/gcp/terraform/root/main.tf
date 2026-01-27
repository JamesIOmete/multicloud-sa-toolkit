provider "google" {
  project = var.project_id
  region  = var.region
  impersonate_service_account = var.impersonate_service_account
}

data "google_project" "project" {}

locals {
  common_labels = {
    toolkit     = "multicloud-sa-toolkit"
    use_case    = "04-ephemeral-sandbox"
    env         = var.env
    owner       = var.owner
    managed_by  = "terraform"
    sandbox_id  = var.sandbox_id
  }
  billing_account = replace(var.billing_account_id, "billingAccounts/", "")
}

# --- 1. Networking ---

resource "google_compute_network" "vpc" {
  name                    = format("%s-%s-vpc-%s", var.name_prefix, var.env, var.sandbox_id)
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = format("%s-%s-subnet-%s", var.name_prefix, var.env, var.sandbox_id)
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
}

# --- 2. Compute (Cloud Run) ---

resource "google_cloud_run_v2_service" "default" {
  name     = format("%s-%s-app-%s", var.name_prefix, var.env, var.sandbox_id)
  location = var.region
  labels   = local.common_labels
  deletion_protection = false

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }

  traffic {
    percent         = 100
    type            = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# --- 3. Cost Controls ---

resource "google_billing_budget" "budget" {
  billing_account = local.billing_account
  display_name    = format("%s-%s-budget-%s", var.name_prefix, var.env, var.sandbox_id)

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
