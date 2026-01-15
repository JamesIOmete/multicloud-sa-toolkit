locals {
  base_tags = {
    "toolkit"    = "multicloud-sa-toolkit"
    "use_case"   = "01-landing-zone-lite"
    "managed_by" = "terraform"
  }

  tags = merge(local.base_tags, var.tags)

  sns_topic_name = "${var.name_prefix}-cost-alerts"
}

resource "aws_sns_topic" "alerts" {
  count = var.enable_budgets || var.enable_anomaly_detection ? 1 : 0

  name = local.sns_topic_name

  tags = local.tags
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.enable_budgets || var.enable_anomaly_detection ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns_publish[0].json
}

data "aws_iam_policy_document" "sns_publish" {
  count = var.enable_budgets || var.enable_anomaly_detection ? 1 : 0

  statement {
    sid    = "AllowBudgetAndAnomalyServices"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "budgets.amazonaws.com",
        "ce.amazonaws.com"
      ]
    }

    actions = ["sns:Publish"]

    resources = [aws_sns_topic.alerts[0].arn]
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = (var.enable_budgets || var.enable_anomaly_detection) ? toset(var.notification_emails) : []

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.key
}

################################################################################
# AWS Budgets (monthly cost budget)
################################################################################

resource "aws_budgets_budget" "monthly" {
  count = var.enable_budgets ? 1 : 0

  name         = "${var.name_prefix}-monthly-budget"
  budget_type  = "COST"
  limit_amount = format("%.2f", var.monthly_budget_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  cost_filters = {}
  cost_types {
    include_credit             = true
    include_discounts          = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = true
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_amortized              = false
    use_blended                = false
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator = "GREATER_THAN"
      threshold           = notification.value
      threshold_type      = "PERCENTAGE"
      notification_type   = "FORECASTED"

      subscriber {
        subscription_type = "SNS"
        address           = aws_sns_topic.alerts[0].arn
      }
    }
  }

  tags = local.tags
}

################################################################################
# Cost anomaly detection (Cost Explorer)
################################################################################

resource "aws_ce_anomaly_monitor" "account" {
  count = var.enable_anomaly_detection ? 1 : 0

  name              = "${var.name_prefix}-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "account" {
  count = var.enable_anomaly_detection ? 1 : 0

  name      = "${var.name_prefix}-anomaly-subscription"
  frequency = var.anomaly_frequency
  threshold = var.anomaly_threshold

  monitor_arn_list = [aws_ce_anomaly_monitor.account[0].arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.alerts[0].arn
  }
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic receiving cost alerts"
  value       = try(aws_sns_topic.alerts[0].arn, null)
}
