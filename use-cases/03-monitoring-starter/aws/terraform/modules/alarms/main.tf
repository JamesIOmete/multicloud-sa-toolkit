locals {
  base_name = var.name_prefix != "" ? var.name_prefix : "mcsa-uc03-${var.env}"
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "03-monitoring-starter",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform"
  }, var.additional_tags)
}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "${local.base_name}-queue-depth"
  alarm_description   = "Alert when SQS token queue depth exceeds threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = var.queue_period_seconds
  statistic           = "Average"
  threshold           = var.queue_depth_threshold
  alarm_actions       = [var.alarm_topic_arn]
  ok_actions          = [var.alarm_topic_arn]

  dimensions = {
    QueueName = var.queue_name
  }

  treat_missing_data = "notBreaching"

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "queue_latency" {
  alarm_name          = "${local.base_name}-queue-age"
  alarm_description   = "Alert when SQS token queue message age grows"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = var.queue_period_seconds
  statistic           = "Maximum"
  threshold           = var.queue_age_threshold
  alarm_actions       = [var.alarm_topic_arn]
  ok_actions          = [var.alarm_topic_arn]

  dimensions = {
    QueueName = var.queue_name
  }

  treat_missing_data = "notBreaching"

  tags = local.tags
}

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "${local.base_name}-starter-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "text"
        x    = 0
        y    = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# UC03 Monitoring Starter\nToken workloads + key metrics"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 2
        width  = 12
        height = 6
        properties = {
          title  = "Queue depth"
          metrics = [
            [ "AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.queue_name ]
          ]
          period = var.queue_period_seconds
          stat   = "Average"
          region = var.aws_region
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 2
        width  = 12
        height = 6
        properties = {
          title  = "Oldest message age"
          metrics = [
            [ "AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", var.queue_name ]
          ]
          period = var.queue_period_seconds
          stat   = "Maximum"
          region = var.aws_region
        }
      }
    ]
  })
}

output "dashboard_name" {
  value       = aws_cloudwatch_dashboard.overview.dashboard_name
  description = "Name of CloudWatch dashboard"
}

output "queue_depth_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.queue_depth.arn
  description = "ARN of queue depth alarm"
}

output "queue_age_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.queue_latency.arn
  description = "ARN of queue age alarm"
}
