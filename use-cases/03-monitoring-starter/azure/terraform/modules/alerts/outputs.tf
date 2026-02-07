output "action_group_id" {
  description = "Action group ID for alerts"
  value       = azurerm_monitor_action_group.alerts.id
}

output "metric_alert_ids" {
  description = "Metric alert IDs"
  value = [
    azurerm_monitor_metric_alert.backlog.id,
    azurerm_monitor_metric_alert.deadletter.id
  ]
}
