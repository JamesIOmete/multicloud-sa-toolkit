output "storage_account_name" {
  description = "Name of the storage account used for log archival"
  value       = var.enable_storage_archive ? azurerm_storage_account.logs[0].name : null
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID (if enabled)"
  value       = var.enable_log_analytics ? azurerm_log_analytics_workspace.logs[0].id : null
}

output "activity_log_diagnostic_setting_id" {
  description = "Diagnostic setting ID for subscription activity logs"
  value       = azurerm_monitor_diagnostic_setting.activity_logs.id
}

output "resource_group_name" {
  description = "Resource group holding logging resources"
  value       = azurerm_resource_group.logs.name
}
