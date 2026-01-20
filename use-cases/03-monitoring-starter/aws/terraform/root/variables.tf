variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "env" {
  type        = string
  description = "Environment identifier"
  default     = "toolkit-test"
}

variable "owner" {
  type        = string
  description = "Owner tag for resources"
  default     = "platform-team"
}

variable "name_prefix" {
  type        = string
  description = "Optional prefix override"
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags merged into defaults"
  default     = {}
}

variable "notification_emails" {
  type        = list(string)
  description = "Email recipients for monitoring alerts"
  default     = []
}

variable "use_existing_topic_arn" {
  type        = string
  description = "Existing SNS topic ARN for alerts (skip creation when set)"
  default     = ""
}

variable "monitoring_topic_name_override" {
  type        = string
  description = "Optional SNS topic name override"
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch Logs retention for token workload"
  default     = 30
}

variable "log_kms_key_arn" {
  type        = string
  description = "Optional KMS key for log group encryption"
  default     = ""
}

variable "queue_visibility_timeout" {
  type        = number
  description = "SQS queue visibility timeout in seconds"
  default     = 30
}

variable "queue_retention_seconds" {
  type        = number
  description = "SQS message retention period in seconds"
  default     = 345600
}

variable "queue_receive_wait" {
  type        = number
  description = "SQS receive wait time in seconds"
  default     = 5
}

variable "queue_delay_seconds" {
  type        = number
  description = "SQS delivery delay in seconds"
  default     = 0
}

variable "queue_period_seconds" {
  type        = number
  description = "Evaluation period for queue alarms"
  default     = 60
}

variable "queue_depth_threshold" {
  type        = number
  description = "Threshold for queue depth alarm"
  default     = 100
}

variable "queue_age_threshold" {
  type        = number
  description = "Threshold (seconds) for queue age alarm"
  default     = 120
}
