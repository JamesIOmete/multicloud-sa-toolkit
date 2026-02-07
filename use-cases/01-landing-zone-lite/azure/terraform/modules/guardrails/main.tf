data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "deny_public_ip" {
  display_name = "Not allowed resource types"
}

locals {
  assignment_prefix = substr(var.name_prefix, 0, 40)
  metadata          = jsonencode(var.tags)
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "${local.assignment_prefix}-allowed-locations"
  display_name         = "${var.name_prefix} Allowed Locations"
  subscription_id      = var.subscription_resource_id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  metadata             = local.metadata

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

resource "azurerm_subscription_policy_assignment" "deny_public_ip" {
  name                 = "${local.assignment_prefix}-deny-public-ip"
  display_name         = "${var.name_prefix} Deny Public IPs"
  subscription_id      = var.subscription_resource_id
  policy_definition_id = data.azurerm_policy_definition.deny_public_ip.id
  metadata             = local.metadata

  parameters = jsonencode({
    listOfResourceTypesNotAllowed = {
      value = ["Microsoft.Network/publicIPAddresses"]
    }
  })
}
