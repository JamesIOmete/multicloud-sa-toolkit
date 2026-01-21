variable "base_name" {
  type        = string
  description = "Base name for sandbox resources"
}

variable "sandbox_id" {
  type        = string
  description = "Sandbox identifier"
}

variable "env" {
  type        = string
  description = "Environment tag"
}

variable "owner" {
  type        = string
  description = "Owner tag"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags merged into defaults"
  default     = {}
}

variable "monthly_budget_amount" {
  type        = number
  description = "Monthly cost budget amount (USD)"
}

variable "budget_threshold_percent" {
  type        = number
  description = "Forecasted budget threshold percentage"
  default     = 80
}

variable "anomaly_threshold_amount" {
  type        = number
  description = "Absolute anomaly threshold (USD)"
  default     = 20
}

variable "alert_topic_arn" {
  type        = string
  description = "SNS topic ARN for budget/anomaly alerts"
}

variable "enable_cost_anomaly_monitor" {
  type        = bool
  description = "Create Cost Explorer anomaly monitor and subscription"
  default     = true
}
