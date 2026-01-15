variable "name_prefix" {
  description = "Base prefix for cost control resources"
  type        = string
}

variable "tags" {
  description = "Additional tags for created resources"
  type        = map(string)
  default     = {}
}

variable "enable_budgets" {
  description = "Toggle creation of AWS Budgets"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100.0
}

variable "budget_thresholds" {
  description = "Percentage thresholds for budget alerts"
  type        = list(number)
  default     = [50, 80, 100]
}

variable "notification_emails" {
  description = "Email recipients for cost alerts"
  type        = list(string)
  default     = []
}

variable "enable_anomaly_detection" {
  description = "Toggle AWS Cost Explorer anomaly detection"
  type        = bool
  default     = true
}

variable "anomaly_threshold" {
  description = "Dollar threshold for anomaly detection alerts"
  type        = number
  default     = 50.0
}

variable "anomaly_frequency" {
  description = "Frequency for anomaly notifications"
  type        = string
  default     = "DAILY"
  validation {
    condition     = contains(["DAILY", "IMMEDIATE", "WEEKLY"], var.anomaly_frequency)
    error_message = "anomaly_frequency must be one of DAILY, IMMEDIATE, WEEKLY"
  }
}
