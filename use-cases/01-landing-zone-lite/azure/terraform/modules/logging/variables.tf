variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "subscription_id" {
  description = "Subscription ID used for naming"
  type        = string
}

variable "subscription_resource_id" {
  description = "Subscription resource ID for diagnostic settings"
  type        = string
}

variable "enable_storage_archive" {
  description = "Archive subscription activity logs to a storage account"
  type        = bool
  default     = true
}

variable "enable_log_analytics" {
  description = "Send subscription activity logs to Log Analytics"
  type        = bool
  default     = false
}

variable "storage_account_name" {
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
