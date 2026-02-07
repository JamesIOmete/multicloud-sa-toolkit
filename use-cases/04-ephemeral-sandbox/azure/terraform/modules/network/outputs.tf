output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.sandbox.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = azurerm_subnet.sandbox.name
}
