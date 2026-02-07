output "budget_name" {
  description = "Budget name"
  value       = azurerm_consumption_budget_subscription.monthly.name
}
