provider "google" {
  project = var.project_id
  region  = var.region
}

# --- 1. Token Workload (Pub/Sub + Cloud Function) ---

resource "google_pubsub_topic" "topic" {
  name = format("%s-%s-topic", var.name_prefix, var.env)
}

resource "google_storage_bucket" "source_bucket" {
  name          = format("%s-%s-source-bucket", var.name_prefix, var.env)
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "source_bucket_reader" {
  bucket = google_storage_bucket.source_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_storage_bucket_object" "source_archive" {
  name   = "source.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.source.output_path
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/function_source"
  output_path = "${path.module}/source.zip"
}

resource "google_cloudfunctions2_function" "function" {
  name     = format("%s-%s-function", var.name_prefix, var.env)
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "nodejs20"
    entry_point = "helloPubSub"
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.source_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256Mi"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_ALL"
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

data "google_project" "project" {}

# Cloud Build needs to push artifacts for Cloud Functions v2 builds.
resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Subscription used for backlog monitoring.
resource "google_pubsub_subscription" "subscription" {
  name  = format("%s-%s-subscription", var.name_prefix, var.env)
  topic = google_pubsub_topic.topic.name
}

# --- 2. Monitoring and Alerting ---

resource "google_monitoring_notification_channel" "sms" {
  display_name = "SMS Notification"
  type         = "sms"
  labels = {
    number       = var.notification_sms_number
  }
}

resource "google_monitoring_alert_policy" "pubsub_backlog" {
  display_name = "Pub/Sub Backlog Alert"
  combiner     = "OR"
  conditions {
    display_name = "High number of undelivered messages"
    condition_threshold {
      filter     = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" resource.type=\"pubsub_subscription\" resource.label.\"subscription_id\"=\"${google_pubsub_subscription.subscription.name}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 10
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.sms.id
  ]
}

resource "google_monitoring_alert_policy" "function_errors" {
  display_name = "Cloud Function Error Alert"
  combiner     = "OR"
  conditions {
    display_name = "Function execution errors"
    condition_threshold {
      filter     = "metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" resource.type=\"cloud_function\" resource.label.\"function_name\"=\"${google_cloudfunctions2_function.function.name}\" metric.label.\"status\"=\"error\""
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
      }
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.sms.id
  ]
}
