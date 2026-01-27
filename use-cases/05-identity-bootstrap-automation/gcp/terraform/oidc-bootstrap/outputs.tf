output "workload_identity_pool_id" {
  description = "The ID of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.github_pool.id
}

output "workload_identity_pool_provider_id" {
  description = "The ID of the Workload Identity Pool Provider."
  value       = google_iam_workload_identity_pool_provider.github_provider.id
}

output "service_account_email" {
  description = "The email of the created Service Account."
  value       = google_service_account.github_actions_sa.email
}

output "workload_identity_user_iam_member" {
  description = "The IAM member for the Workload Identity User role."
  value       = google_project_iam_member.workload_identity_user.member
}