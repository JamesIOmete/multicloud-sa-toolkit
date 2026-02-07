output "namespace_name" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.token.name
}

output "namespace_id" {
  description = "Service Bus namespace resource ID"
  value       = azurerm_servicebus_namespace.token.id
}

output "queue_name" {
  description = "Service Bus queue name"
  value       = azurerm_servicebus_queue.token.name
}

output "queue_id" {
  description = "Service Bus queue resource ID"
  value       = azurerm_servicebus_queue.token.id
}
