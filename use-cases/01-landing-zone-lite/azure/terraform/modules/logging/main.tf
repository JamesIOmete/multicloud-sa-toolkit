locals {
  storage_suffix       = substr(md5(var.subscription_id), 0, 6)
  storage_base         = substr(replace(lower(var.name_prefix), "-", ""), 0, 18)
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "${local.storage_base}${local.storage_suffix}"
  activity_log_categories = [
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth"
  ]
}

resource "azurerm_resource_group" "logs" {
  name     = "${var.name_prefix}-logging-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "logs" {
  count                           = var.enable_storage_archive ? 1 : 0
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.logs.name
  location                        = azurerm_resource_group.logs.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_management_policy" "logs" {
  count              = var.enable_storage_archive && var.storage_retention_days > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.logs[0].id

  rule {
    name    = "expire-activity-logs"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.storage_retention_days
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "logs" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${var.name_prefix}-law"
  location            = azurerm_resource_group.logs.location
  resource_group_name = azurerm_resource_group.logs.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name                       = "${var.name_prefix}-activity-logs"
  target_resource_id         = var.subscription_resource_id
  storage_account_id         = var.enable_storage_archive ? azurerm_storage_account.logs[0].id : null
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.logs[0].id : null

  dynamic "enabled_log" {
    for_each = toset(local.activity_log_categories)

    content {
      category = enabled_log.value
    }
  }
}
