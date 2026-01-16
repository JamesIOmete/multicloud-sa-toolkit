locals {
  base_tags = {
    "toolkit"    = "multicloud-sa-toolkit"
    "use_case"   = "01-landing-zone-lite"
    "managed_by" = "terraform"
  }

  tags = merge(local.base_tags, var.tags)

  sns_topic_name = "${var.name_prefix}-alerts"
}

resource "aws_sns_topic" "alerts" {
  count = var.enable_guardrail_alerts ? 1 : 0

  name = local.sns_topic_name

  tags = local.tags
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.enable_guardrail_alerts ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns_publish[0].json
}

data "aws_iam_policy_document" "sns_publish" {
  count = var.enable_guardrail_alerts ? 1 : 0

  statement {
    sid    = "AllowEventBridge"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sns:Publish"
    ]

    resources = [aws_sns_topic.alerts[0].arn]
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.enable_guardrail_alerts ? toset(var.notification_emails) : []

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.key
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "cloudtrail" {
  count = var.enable_guardrail_alerts ? 1 : 0

  name        = "${var.name_prefix}-cloudtrail-guardrail"
  description = "Alert on CloudTrail being disabled or modified"

  event_pattern = jsonencode({
    "source" : ["aws.cloudtrail"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["cloudtrail.amazonaws.com"],
      "eventName" : ["StopLogging", "DeleteTrail", "UpdateTrail", "PutEventSelectors", "PutInsightSelectors"]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "config" {
  count = var.enable_guardrail_alerts && var.enable_config_guardrails ? 1 : 0

  name        = "${var.name_prefix}-config-guardrail"
  description = "Alert on AWS Config being disabled or modified"

  event_pattern = jsonencode({
    "source" : ["aws.config"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["config.amazonaws.com"],
      "eventName" : [
        "StopConfigurationRecorder",
        "DeleteConfigurationRecorder",
        "PutConfigurationRecorder",
        "DeleteDeliveryChannel",
        "PutDeliveryChannel"
      ]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "cloudtrail" {
  count = var.enable_guardrail_alerts ? 1 : 0

  rule      = aws_cloudwatch_event_rule.cloudtrail[0].name
  target_id = "sns"
  arn       = aws_sns_topic.alerts[0].arn
}

resource "aws_cloudwatch_event_target" "config" {
  count = var.enable_guardrail_alerts && var.enable_config_guardrails ? 1 : 0

  rule      = aws_cloudwatch_event_rule.config[0].name
  target_id = "sns"
  arn       = aws_sns_topic.alerts[0].arn
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_logging" {
  count = var.enable_guardrail_alerts ? 1 : 0

  alarm_name          = "${var.name_prefix}-cloudtrail-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryErrors"
  namespace           = "AWS/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    TrailName = "${var.name_prefix}-trail"
  }

  alarm_description = "CloudTrail delivery errors detected"
  alarm_actions     = [aws_sns_topic.alerts[0].arn]

  tags = local.tags
}

################################################################################
# Optional SCP pack
################################################################################

data "aws_organizations_organization" "current" {
  count = var.enable_scp_pack ? 1 : 0
}

locals {
  scp_policy_content = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyDisablingCloudTrail",
        "Effect" : "Deny",
        "Action" : [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "DenyDisablingConfig",
        "Effect" : "Deny",
        "Action" : [
          "config:DeleteConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "config:DeleteDeliveryChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "guardrails" {
  count = var.enable_scp_pack ? 1 : 0

  name        = "${var.name_prefix}-guardrails"
  description = "UC01 guardrail SCP to prevent disabling CloudTrail/Config"
  type        = "SERVICE_CONTROL_POLICY"
  content     = local.scp_policy_content
}

resource "aws_organizations_policy_attachment" "guardrails" {
  for_each = var.enable_scp_pack ? toset(var.scp_target_ids) : []

  policy_id = aws_organizations_policy.guardrails[0].id
  target_id = each.key
}
