provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "reader" {
  name  = "Reader"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "resource_graph" {
  count = var.enable_resource_graph_role ? 1 : 0
  name  = "Resource Graph Reader"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "reader" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = data.azurerm_role_definition.reader.id
  principal_id       = var.principal_object_id
}

resource "azurerm_role_assignment" "resource_graph" {
  count              = var.enable_resource_graph_role ? 1 : 0
  scope              = data.azurerm_subscription.current.id
  role_definition_id = data.azurerm_role_definition.resource_graph[0].id
  principal_id       = var.principal_object_id
}
