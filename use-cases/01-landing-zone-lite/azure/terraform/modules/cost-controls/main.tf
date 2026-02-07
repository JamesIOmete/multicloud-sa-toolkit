locals {
  budget_name       = substr("${var.name_prefix}-monthly-budget", 0, 64)
  budget_start_date = var.budget_start_date != "" ? var.budget_start_date : formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = local.budget_name
  subscription_id = var.subscription_resource_id
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  dynamic "notification" {
    for_each = toset(var.budget_thresholds)

    content {
      enabled        = true
      operator       = "GreaterThan"
      threshold      = notification.value
      threshold_type = "Actual"
      contact_emails = var.cost_notification_emails
    }
  }
}
