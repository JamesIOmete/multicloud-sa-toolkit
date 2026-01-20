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
  description = "Optional name prefix override"
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to merge into defaults"
  default     = {}
}

variable "queue_visibility_timeout" {
  type        = number
  description = "SQS queue visibility timeout in seconds"
  default     = 30
}

variable "queue_retention_seconds" {
  type        = number
  description = "SQS message retention in seconds"
  default     = 345600
}

variable "queue_receive_wait" {
  type        = number
  description = "SQS long polling wait time in seconds"
  default     = 5
}

variable "queue_delay_seconds" {
  type        = number
  description = "Initial delay for messages in seconds"
  default     = 0
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "log_kms_key_arn" {
  type        = string
  description = "Optional KMS key ARN for log encryption"
  default     = ""
}
