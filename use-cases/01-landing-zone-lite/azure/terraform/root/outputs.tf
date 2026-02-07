output "log_storage_account_name" {
  description = "Storage account name used for activity log archiving"
  value       = try(module.logging[0].storage_account_name, null)
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (if enabled)"
  value       = try(module.logging[0].log_analytics_workspace_id, null)
}

output "activity_log_diagnostic_setting_id" {
  description = "Diagnostic setting ID for subscription activity logs"
  value       = try(module.logging[0].activity_log_diagnostic_setting_id, null)
}

output "policy_assignment_ids" {
  description = "Policy assignment IDs applied by the guardrails module"
  value       = try(module.guardrails[0].policy_assignment_ids, [])
}

output "budget_name" {
  description = "Name of the subscription budget"
  value       = try(module.cost_controls[0].budget_name, null)
}
