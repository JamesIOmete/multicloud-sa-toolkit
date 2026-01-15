locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : format("mcsa-uc01-%s", var.env)

  base_tags = {
    toolkit    = "multicloud-sa-toolkit"
    use_case   = "01-landing-zone-lite"
    env        = var.env
    owner      = var.owner
    managed_by = "terraform"
  }

  tags = merge(local.base_tags, var.additional_tags)
}

module "logging" {
  count = var.enable_logging ? 1 : 0

  source = "../modules/logging"

  name_prefix                          = local.name_prefix
  tags                                 = local.tags
  log_bucket_name                      = var.log_bucket_name
  kms_alias                            = var.kms_alias
  s3_retention_days                    = var.s3_retention_days
  kms_key_rotation_enabled             = var.kms_key_rotation_enabled
  kms_deletion_window                  = var.kms_deletion_window
  enable_cloudtrail                    = var.enable_cloudtrail
  cloudtrail_multi_region              = var.cloudtrail_multi_region
  enable_cloudwatch_logs               = var.enable_cloudwatch_logs
  cloudwatch_retention_days            = var.cloudwatch_retention_days
  enable_config                        = var.enable_config
  config_record_all_supported          = var.config_record_all_supported
  config_include_global_resource_types = var.config_include_global_resource_types
}

module "guardrails" {
  count = var.enable_guardrails ? 1 : 0

  source = "../modules/guardrails"

  name_prefix              = local.name_prefix
  tags                     = local.tags
  enable_guardrail_alerts  = var.enable_guardrail_alerts
  enable_config_guardrails = var.enable_config_guardrails
  notification_emails      = var.guardrail_notification_emails
  enable_scp_pack          = var.enable_scp_pack
  scp_target_ids           = var.scp_target_ids
}

module "cost_controls" {
  count = var.enable_cost_controls ? 1 : 0

  source = "../modules/cost-controls"

  name_prefix              = local.name_prefix
  tags                     = local.tags
  enable_budgets           = var.enable_budgets
  monthly_budget_amount    = var.monthly_budget_amount
  budget_thresholds        = var.budget_thresholds
  notification_emails      = var.cost_notification_emails
  enable_anomaly_detection = var.enable_anomaly_detection
  anomaly_threshold        = var.anomaly_threshold
  anomaly_frequency        = var.anomaly_frequency
}
