output "servicebus_namespace_name" {
  description = "Service Bus namespace name"
  value       = try(module.token_workload[0].namespace_name, null)
}

output "servicebus_queue_name" {
  description = "Service Bus queue name"
  value       = try(module.token_workload[0].queue_name, null)
}

output "action_group_id" {
  description = "Action group ID for alerts"
  value       = try(module.alerts[0].action_group_id, null)
}

output "metric_alert_ids" {
  description = "Metric alert IDs"
  value       = try(module.alerts[0].metric_alert_ids, [])
}
