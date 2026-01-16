locals {
  base_tags = {
    "toolkit"    = "multicloud-sa-toolkit"
    "use_case"   = "01-landing-zone-lite"
    "managed_by" = "terraform"
  }

  tags = merge(local.base_tags, var.tags)

  sns_topic_name  = "${var.name_prefix}-cost-alerts"
  anomaly_use_sns = var.anomaly_frequency == "IMMEDIATE"
  sns_publish_services = concat(
    ["budgets.amazonaws.com"],
    local.anomaly_use_sns ? ["costalerts.amazonaws.com"] : []
  )
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

  dynamic "statement" {
    for_each = toset(local.sns_publish_services)

    content {
      sid    = "AllowPublish-${replace(statement.value, ".", "-")}"
      effect = "Allow"

      principals {
        type = "Service"
        identifiers = [
          statement.value,
        ]
      }

      actions = ["sns:Publish"]

      resources = [aws_sns_topic.alerts[0].arn]
    }
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
    use_amortized              = false
    use_blended                = false
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator       = "GREATER_THAN"
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "FORECASTED"
      subscriber_sns_topic_arns = [aws_sns_topic.alerts[0].arn]
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

  monitor_arn_list = [aws_ce_anomaly_monitor.account[0].arn]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = [tostring(var.anomaly_threshold)]
    }
  }

  dynamic "subscriber" {
    for_each = local.anomaly_use_sns ? [aws_sns_topic.alerts[0].arn] : var.notification_emails
    content {
      type    = local.anomaly_use_sns ? "SNS" : "EMAIL"
      address = subscriber.value
    }
  }
}
