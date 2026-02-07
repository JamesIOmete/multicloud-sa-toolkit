variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for alerting resources"
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

variable "notification_emails" {
  description = "Email addresses for alert notifications"
  type        = list(string)
}

variable "namespace_resource_id" {
  description = "Service Bus namespace resource ID to monitor"
  type        = string
}

variable "queue_name" {
  description = "Service Bus queue name to monitor"
  type        = string
}

variable "backlog_threshold" {
  description = "Threshold for ActiveMessages metric"
  type        = number
}

variable "deadletter_threshold" {
  description = "Threshold for DeadletteredMessages metric"
  type        = number
}
