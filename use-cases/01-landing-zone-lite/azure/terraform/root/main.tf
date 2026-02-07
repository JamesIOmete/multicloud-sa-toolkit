provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : "mcsa-uc01-${var.env}"
  tags = merge(
    {
      toolkit    = "multicloud-sa-toolkit"
      use_case   = "01-landing-zone-lite"
      env        = var.env
      owner      = var.owner
      managed_by = "terraform"
    },
    var.additional_tags
  )
}

module "logging" {
  source = "../modules/logging"
  count  = var.enable_logging ? 1 : 0

  name_prefix                  = local.name_prefix
  location                     = var.location
  tags                         = local.tags
  subscription_id              = data.azurerm_subscription.current.subscription_id
  subscription_resource_id     = data.azurerm_subscription.current.id
  enable_storage_archive       = var.enable_storage_archive
  enable_log_analytics         = var.enable_log_analytics
  storage_account_name         = var.log_storage_account_name
  log_analytics_retention_days = var.log_analytics_retention_days
  storage_retention_days       = var.storage_retention_days
}

module "guardrails" {
  source = "../modules/guardrails"
  count  = var.enable_guardrails ? 1 : 0

  name_prefix              = local.name_prefix
  tags                     = local.tags
  subscription_resource_id = data.azurerm_subscription.current.id
  allowed_locations        = var.allowed_locations
}

module "cost_controls" {
  source = "../modules/cost-controls"
  count  = var.enable_cost_controls ? 1 : 0

  name_prefix              = local.name_prefix
  subscription_resource_id = data.azurerm_subscription.current.id
  monthly_budget_amount    = var.monthly_budget_amount
  budget_thresholds        = var.budget_thresholds
  cost_notification_emails = var.cost_notification_emails
  budget_start_date        = var.budget_start_date
}
