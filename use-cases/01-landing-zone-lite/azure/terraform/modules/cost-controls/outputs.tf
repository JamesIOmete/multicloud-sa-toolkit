output "budget_name" {
  description = "Name of the subscription budget"
  value       = azurerm_consumption_budget_subscription.monthly.name
}
