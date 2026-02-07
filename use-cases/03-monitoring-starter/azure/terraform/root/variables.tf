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
  description = "Override for the default mcsa-uc03-<env> prefix"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags merged into every tagged resource"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus2"
}

################################################################################
# Workload toggles
################################################################################

variable "enable_workload" {
  description = "Enable the Service Bus token workload"
  type        = bool
  default     = true
}

variable "servicebus_sku" {
  description = "Service Bus SKU (Basic or Standard)"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard"], var.servicebus_sku)
    error_message = "servicebus_sku must be Basic or Standard."
  }
}

################################################################################
# Alerting toggles
################################################################################

variable "enable_alerts" {
  description = "Enable Azure Monitor metric alerts"
  type        = bool
  default     = true
}

variable "notification_emails" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
  validation {
    condition     = var.enable_alerts == false || length(var.notification_emails) > 0
    error_message = "notification_emails must include at least one address when alerts are enabled."
  }
}

variable "namespace_resource_id" {
  description = "Existing Service Bus namespace resource ID (required if enable_workload=false)"
  type        = string
  default     = ""
  validation {
    condition     = var.enable_alerts == false || var.enable_workload || var.namespace_resource_id != ""
    error_message = "namespace_resource_id is required when alerts are enabled and enable_workload is false."
  }
}

variable "queue_name" {
  description = "Existing Service Bus queue name (required if enable_workload=false)"
  type        = string
  default     = ""
  validation {
    condition     = var.enable_alerts == false || var.enable_workload || var.queue_name != ""
    error_message = "queue_name is required when alerts are enabled and enable_workload is false."
  }
}

variable "backlog_threshold" {
  description = "Threshold for ActiveMessages metric"
  type        = number
  default     = 10
}

variable "deadletter_threshold" {
  description = "Threshold for DeadletteredMessages metric"
  type        = number
  default     = 1
}
