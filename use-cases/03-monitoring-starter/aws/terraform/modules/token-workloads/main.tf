locals {
  base_name = var.name_prefix != "" ? var.name_prefix : "mcsa-uc03-${var.env}"
  tags = merge({
    toolkit   = "multicloud-sa-toolkit",
    use_case  = "03-monitoring-starter",
    env       = var.env,
    owner     = var.owner,
    managed_by = "terraform"
  }, var.additional_tags)
}

resource "aws_sqs_queue" "app_queue" {
  name                        = "${local.base_name}-app-queue"
  visibility_timeout_seconds  = var.queue_visibility_timeout
  message_retention_seconds   = var.queue_retention_seconds
  receive_wait_time_seconds   = var.queue_receive_wait
  delay_seconds               = var.queue_delay_seconds

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/mcsa/${local.base_name}/app"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = local.tags
}
