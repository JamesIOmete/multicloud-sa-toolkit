resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  base_name      = "sb${replace(replace(lower(var.name_prefix), "-", ""), "_", "")}"
  namespace_name = substr("${local.base_name}${random_string.suffix.result}", 0, 50)
  queue_name     = substr("${replace(replace(replace(lower(var.name_prefix), "_", "-"), " ", "-"), "/", "-")}-queue", 0, 50)
}

resource "azurerm_servicebus_namespace" "token" {
  name                = local.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "token" {
  name                = local.queue_name
  namespace_id        = azurerm_servicebus_namespace.token.id
}
