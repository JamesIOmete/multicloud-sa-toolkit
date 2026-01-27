output "log_bucket_name" {
  description = "The name of the Cloud Storage bucket for logs."
  value       = google_storage_bucket.log_bucket.name
}

output "log_sink_name" {
  description = "The name of the Cloud Logging sink."
  value       = google_logging_project_sink.log_sink.name
}

output "billing_budget_id" {
  description = "The ID of the billing budget."
  value       = google_billing_budget.budget.id
}
