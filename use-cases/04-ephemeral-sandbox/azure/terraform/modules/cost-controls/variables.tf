variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "subscription_resource_id" {
  description = "Subscription resource ID for budget scope"
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
}

variable "budget_thresholds" {
  description = "Threshold percentages for budget alerts"
  type        = list(number)
}

variable "notification_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
}

variable "budget_start_date" {
  description = "Budget start date in RFC3339 format"
  type        = string
}
