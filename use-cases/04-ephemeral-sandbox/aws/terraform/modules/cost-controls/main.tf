locals {
  base_name = "${var.base_name}-${var.sandbox_id}"
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "04-ephemeral-sandbox",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform",
    sandbox_id = var.sandbox_id
  }, var.additional_tags)
}

resource "time_static" "budget_start" {}

resource "aws_budgets_budget" "sandbox" {
  name              = "${local.base_name}-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  time_period_start = formatdate("YYYY-MM-01_00:00", time_static.budget_start.rfc3339)
  time_period_end   = "2087-06-15_00:00"

  cost_types {
    include_credit             = true
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
    use_amortized              = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = var.budget_threshold_percent
    threshold_type             = "PERCENTAGE"
    subscriber_sns_topic_arns  = [var.alert_topic_arn]
  }

  tags = local.tags
}

resource "aws_ce_anomaly_monitor" "sandbox" {
  count             = var.enable_cost_anomaly_monitor ? 1 : 0
  name              = "${local.base_name}-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "sandbox" {
  count           = var.enable_cost_anomaly_monitor ? 1 : 0
  name            = "${local.base_name}-anomaly-subscription"
  frequency       = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.sandbox[count.index].arn]

  threshold_expression {
    dimension {
      key    = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values = [tostring(var.anomaly_threshold_amount)]
    }
  }

  subscriber {
    type    = "SNS"
    address = var.alert_topic_arn
  }
}

output "budget_id" {
  value = aws_budgets_budget.sandbox.id
}

output "anomaly_subscription_arn" {
  value = var.enable_cost_anomaly_monitor ? aws_ce_anomaly_subscription.sandbox[0].arn : null
}
