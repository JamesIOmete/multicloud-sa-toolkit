output "resource_group_name" {
  description = "Resource group for the sandbox"
  value       = azurerm_resource_group.sandbox.name
}

output "vnet_name" {
  description = "Sandbox VNet name"
  value       = try(module.network[0].vnet_name, null)
}

output "subnet_name" {
  description = "Sandbox subnet name"
  value       = try(module.network[0].subnet_name, null)
}

output "container_fqdn" {
  description = "FQDN for the sandbox container workload"
  value       = try(module.workload[0].fqdn, null)
}

output "budget_name" {
  description = "Budget name"
  value       = try(module.cost_controls[0].budget_name, null)
}
