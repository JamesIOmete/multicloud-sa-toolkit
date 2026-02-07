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
  description = "Additional tags merged into every tagged resource"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Primary Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "allowed_locations" {
  description = "Azure regions allowed by the guardrail policy"
  type        = list(string)
  default     = ["eastus"]
  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "allowed_locations must contain at least one Azure region."
  }
}

################################################################################
# Logging toggles
################################################################################

variable "enable_logging" {
  description = "Enable the logging baseline module"
  type        = bool
  default     = true
}

variable "enable_storage_archive" {
  description = "Archive subscription activity logs to a storage account"
  type        = bool
  default     = true
  validation {
    condition     = var.enable_logging == false || var.enable_storage_archive || var.enable_log_analytics
    error_message = "At least one of enable_storage_archive or enable_log_analytics must be true when enable_logging is true."
  }
}

variable "enable_log_analytics" {
  description = "Send subscription activity logs to Log Analytics"
  type        = bool
  default     = false
}

variable "log_storage_account_name" {
  description = "Optional override for the log storage account name"
  type        = string
  default     = ""
}

variable "log_analytics_retention_days" {
  description = "Retention period for Log Analytics data"
  type        = number
  default     = 30
}

variable "storage_retention_days" {
  description = "Retention period for activity logs in the storage account"
  type        = number
  default     = 365
}

################################################################################
# Guardrails toggles
################################################################################

variable "enable_guardrails" {
  description = "Enable the guardrails module"
  type        = bool
  default     = true
}

################################################################################
# Cost controls toggles
################################################################################

variable "enable_cost_controls" {
  description = "Enable the cost controls module"
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
  description = "Email addresses subscribed to budget alerts"
  type        = list(string)
  default     = []
  validation {
    condition     = var.enable_cost_controls == false || length(var.cost_notification_emails) > 0
    error_message = "cost_notification_emails must include at least one address when cost controls are enabled."
  }
}

variable "budget_start_date" {
  description = "Budget start date in RFC3339 format (e.g., 2024-01-01T00:00:00Z)"
  type        = string
  default     = ""
}
