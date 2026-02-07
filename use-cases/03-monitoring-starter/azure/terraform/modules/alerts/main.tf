locals {
  short_name = substr(replace(replace(lower(var.name_prefix), "-", ""), "_", ""), 0, 12)
}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "${var.name_prefix}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = local.short_name != "" ? local.short_name : "uc03alerts"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.notification_emails
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "backlog" {
  name                = "${var.name_prefix}-queue-backlog"
  resource_group_name = var.resource_group_name
  scopes              = [var.namespace_resource_id]
  description         = "Active messages in the Service Bus queue exceed threshold."
  severity            = 2
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "ActiveMessages"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.backlog_threshold

    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = [var.queue_name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}

resource "azurerm_monitor_metric_alert" "deadletter" {
  name                = "${var.name_prefix}-queue-deadletter"
  resource_group_name = var.resource_group_name
  scopes              = [var.namespace_resource_id]
  description         = "Dead-lettered messages detected in the Service Bus queue."
  severity            = 2
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "DeadletteredMessages"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.deadletter_threshold

    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = [var.queue_name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
