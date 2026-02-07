resource "azurerm_virtual_network" "sandbox" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "sandbox" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.sandbox.name
  address_prefixes     = [var.subnet_cidr]
}
