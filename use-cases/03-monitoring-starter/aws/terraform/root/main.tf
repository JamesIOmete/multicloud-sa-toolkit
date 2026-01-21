terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  base_name = var.name_prefix != "" ? var.name_prefix : "mcsa-uc03-${var.env}"
  tags = merge({
    toolkit    = "multicloud-sa-toolkit",
    use_case   = "03-monitoring-starter",
    env        = var.env,
    owner      = var.owner,
    managed_by = "terraform"
  }, var.additional_tags)

  topic_name = var.monitoring_topic_name_override != "" ? var.monitoring_topic_name_override : "${local.base_name}-alerts"

  topic_arn = var.use_existing_topic_arn != "" ? var.use_existing_topic_arn : aws_sns_topic.monitoring[0].arn
}

resource "aws_sns_topic" "monitoring" {
  count = var.use_existing_topic_arn == "" ? 1 : 0

  name = local.topic_name
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = {
    for email in var.notification_emails : email => email
    if email != ""
  }

  topic_arn = local.topic_arn
  protocol  = "email"
  endpoint  = each.value
}

module "token_workloads" {
  source = "../modules/token-workloads"

  env              = var.env
  owner            = var.owner
  name_prefix      = local.base_name
  additional_tags  = var.additional_tags
  log_retention_days = var.log_retention_days
  log_kms_key_arn  = var.log_kms_key_arn

  queue_visibility_timeout = var.queue_visibility_timeout
  queue_retention_seconds  = var.queue_retention_seconds
  queue_receive_wait       = var.queue_receive_wait
  queue_delay_seconds      = var.queue_delay_seconds
}

module "alarms" {
  source = "../modules/alarms"

  env             = var.env
  owner           = var.owner
  name_prefix     = local.base_name
  additional_tags = var.additional_tags
  queue_name      = module.token_workloads.queue_name
  alarm_topic_arn = local.topic_arn
  aws_region      = var.aws_region

  queue_period_seconds   = var.queue_period_seconds
  queue_depth_threshold  = var.queue_depth_threshold
  queue_age_threshold    = var.queue_age_threshold
}
