output "vpc_name" {
  description = "The name of the created VPC."
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The name of the created subnet."
  value       = google_compute_subnetwork.subnet.name
}

output "cloud_run_service_url" {
  description = "The URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}

output "billing_budget_id" {
  description = "The ID of the billing budget."
  value       = google_billing_budget.budget.id
}
