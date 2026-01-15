variable "name_prefix" {
  description = "Prefix applied to CloudTrail, IAM roles, and log group names"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with base toolkit tags"
  type        = map(string)
  default     = {}
}

variable "log_bucket_name" {
  description = "Optional override for the CloudTrail/Config log bucket"
  type        = string
  default     = ""
}

variable "kms_alias" {
  description = "Optional override for the KMS alias"
  type        = string
  default     = ""
}

variable "s3_retention_days" {
  description = "Number of days to retain logs in S3"
  type        = number
  default     = 365
}

variable "kms_key_rotation_enabled" {
  description = "Whether to enable annual rotation on the KMS key"
  type        = bool
  default     = true
}

variable "kms_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "enable_cloudtrail" {
  description = "Toggle to create the CloudTrail trail"
  type        = bool
  default     = true
}

variable "cloudtrail_multi_region" {
  description = "Whether the CloudTrail trail should be multi-region"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Whether to stream CloudTrail events to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "Retention period for CloudWatch Logs copy of CloudTrail events"
  type        = number
  default     = 90
}

variable "enable_config" {
  description = "Toggle to enable AWS Config"
  type        = bool
  default     = true
}

variable "config_record_all_supported" {
  description = "Record all supported resource types (AWS Config)"
  type        = bool
  default     = true
}

variable "config_include_global_resource_types" {
  description = "Include global resource types in the AWS Config recorder"
  type        = bool
  default     = true
}
