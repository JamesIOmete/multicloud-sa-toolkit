variable "env" {
  description = "Environment name used in naming and tagging"
  type        = string
  default     = "toolkit-test"
}

variable "owner" {
  description = "Owner tag value for resources"
  type        = string
  default     = "platform-team"
}

variable "name_prefix" {
  description = "Override for the default mcsa-uc01-<env> prefix"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}

################################################################################
# Logging toggles
################################################################################

variable "enable_logging" {
  description = "Enable the logging baseline module"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Optional override for the log bucket name"
  type        = string
  default     = ""
}

variable "kms_alias" {
  description = "Optional override for the KMS alias name"
  type        = string
  default     = ""
}

variable "s3_retention_days" {
  description = "Retention period for log objects in S3"
  type        = number
  default     = 365
}

variable "kms_key_rotation_enabled" {
  description = "Enable annual rotation on the KMS key"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "Deletion window for KMS key (days)"
  type        = number
  default     = 30
}

variable "enable_cloudtrail" {
  description = "Create the CloudTrail trail"
  type        = bool
  default     = true
}

variable "cloudtrail_multi_region" {
  description = "Enable multi-region CloudTrail"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Stream CloudTrail events to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "Retention period for CloudWatch Logs copy of CloudTrail events"
  type        = number
  default     = 90
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "config_record_all_supported" {
  description = "AWS Config records all supported resource types"
  type        = bool
  default     = true
}

variable "config_include_global_resource_types" {
  description = "Include global resource types in AWS Config"
  type        = bool
  default     = true
}

################################################################################
# Guardrails toggles
################################################################################

variable "enable_guardrails" {
  description = "Enable the guardrails module"
  type        = bool
  default     = true
}

variable "enable_guardrail_alerts" {
  description = "Enable EventBridge/SNS alerts for guardrail events"
  type        = bool
  default     = true
}

variable "enable_config_guardrails" {
  description = "Enable Config-specific guardrail alerts"
  type        = bool
  default     = true
}

variable "guardrail_notification_emails" {
  description = "Email addresses subscribed to guardrail alerts"
  type        = list(string)
  default     = []
}

variable "enable_scp_pack" {
  description = "Enable optional AWS Organizations SCP pack"
  type        = bool
  default     = false
}

variable "scp_target_ids" {
  description = "AWS Organizations target IDs (accounts or OUs) for SCP attachment"
  type        = list(string)
  default     = []
}

################################################################################
# Cost controls toggles
################################################################################

variable "enable_cost_controls" {
  description = "Enable the cost controls module"
  type        = bool
  default     = true
}

variable "enable_budgets" {
  description = "Create the monthly AWS budget"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100
}

variable "budget_thresholds" {
  description = "Threshold percentages for budget alerts"
  type        = list(number)
  default     = [50, 80, 100]
}

variable "cost_notification_emails" {
  description = "Email addresses subscribed to cost alerts"
  type        = list(string)
  default     = []
}

variable "enable_anomaly_detection" {
  description = "Enable Cost Explorer anomaly detection"
  type        = bool
  default     = true
}

variable "anomaly_threshold" {
  description = "Dollar threshold for anomaly detection notifications"
  type        = number
  default     = 50
}

variable "anomaly_frequency" {
  description = "Frequency for anomaly detection notifications"
  type        = string
  default     = "DAILY"
  validation {
    condition     = contains(["DAILY", "IMMEDIATE", "WEEKLY"], var.anomaly_frequency)
    error_message = "anomaly_frequency must be one of DAILY, IMMEDIATE, WEEKLY"
  }
}
