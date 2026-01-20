variable "env" {
  type        = string
  description = "Environment tag suffix"
}

variable "owner" {
  type        = string
  description = "Owner tag"
}

variable "name_prefix" {
  type        = string
  description = "Optional naming override"
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to merge"
  default     = {}
}

variable "queue_name" {
  type        = string
  description = "Token workload SQS queue name"
}

variable "alarm_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
}

variable "queue_period_seconds" {
  type        = number
  description = "Evaluation period for SQS metrics"
  default     = 60
}

variable "queue_depth_threshold" {
  type        = number
  description = "Threshold for queue depth alarm"
  default     = 100
}

variable "queue_age_threshold" {
  type        = number
  description = "Threshold for oldest message age alarm (seconds)"
  default     = 120
}

variable "aws_region" {
  type        = string
  description = "AWS region for dashboards"
}
