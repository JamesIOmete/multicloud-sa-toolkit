provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

locals {
  base_prefix    = var.name_prefix != "" ? var.name_prefix : "mcsa-uc04-${var.env}"
  sandbox_prefix = substr("${local.base_prefix}-${var.sandbox_id}", 0, 50)
  tags = merge(
    {
      toolkit    = "multicloud-sa-toolkit"
      use_case   = "04-ephemeral-sandbox"
      env        = var.env
      owner      = var.owner
      managed_by = "terraform"
      sandbox_id = var.sandbox_id
    },
    var.additional_tags
  )
}

resource "azurerm_resource_group" "sandbox" {
  name     = "${local.sandbox_prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../modules/network"
  count  = var.enable_network ? 1 : 0

  name_prefix         = local.sandbox_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.sandbox.name
  tags                = local.tags
  vnet_cidr            = var.vnet_cidr
  subnet_cidr          = var.subnet_cidr
}

module "workload" {
  source = "../modules/workload"
  count  = var.enable_workload ? 1 : 0

  name_prefix         = local.sandbox_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.sandbox.name
  tags                = local.tags
  container_image     = var.container_image
  cpu                 = var.container_cpu
  memory              = var.container_memory
}

module "cost_controls" {
  source = "../modules/cost-controls"
  count  = var.enable_cost_controls ? 1 : 0

  name_prefix           = local.sandbox_prefix
  subscription_resource_id = data.azurerm_subscription.current.id
  monthly_budget_amount = var.monthly_budget_amount
  budget_thresholds     = var.budget_thresholds
  notification_emails   = var.notification_emails
  budget_start_date     = var.budget_start_date
}
