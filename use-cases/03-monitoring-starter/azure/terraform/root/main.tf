provider "azurerm" {
  features {}
}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "mcsa-uc03-${var.env}"
  tags = merge(
    {
      toolkit    = "multicloud-sa-toolkit"
      use_case   = "03-monitoring-starter"
      env        = var.env
      owner      = var.owner
      managed_by = "terraform"
    },
    var.additional_tags
  )
}

resource "azurerm_resource_group" "monitoring" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "token_workload" {
  source = "../modules/token-workload"
  count  = var.enable_workload ? 1 : 0

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name
  tags                = local.tags
  sku                 = var.servicebus_sku
}

module "alerts" {
  source = "../modules/alerts"
  count  = var.enable_alerts ? 1 : 0

  name_prefix           = local.name_prefix
  resource_group_name   = azurerm_resource_group.monitoring.name
  location              = var.location
  tags                  = local.tags
  notification_emails   = var.notification_emails
  namespace_resource_id = var.enable_workload ? module.token_workload[0].namespace_id : var.namespace_resource_id
  queue_name            = var.enable_workload ? module.token_workload[0].queue_name : var.queue_name
  backlog_threshold     = var.backlog_threshold
  deadletter_threshold  = var.deadletter_threshold
}
