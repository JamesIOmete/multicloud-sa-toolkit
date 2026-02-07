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
  description = "Override for the default mcsa-uc04-<env> prefix"
  type        = string
  default     = ""
}

variable "sandbox_id" {
  description = "Unique identifier for the sandbox"
  type        = string
  validation {
    condition     = length(trim(var.sandbox_id, " ")) > 0
    error_message = "sandbox_id must be a non-empty string."
  }
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
# Network toggles
################################################################################

variable "enable_network" {
  description = "Enable the sandbox network"
  type        = bool
  default     = true
}

variable "vnet_cidr" {
  description = "CIDR range for the sandbox VNet"
  type        = string
  default     = "10.60.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR range for the sandbox subnet"
  type        = string
  default     = "10.60.1.0/24"
}

################################################################################
# Workload toggles
################################################################################

variable "enable_workload" {
  description = "Deploy the container sandbox workload"
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Container image for the sandbox workload"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld"
}

variable "container_cpu" {
  description = "CPU cores for the container"
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Memory (GB) for the container"
  type        = number
  default     = 1.5
}

################################################################################
# Cost controls
################################################################################

variable "enable_cost_controls" {
  description = "Enable subscription budget"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 25
}

variable "budget_thresholds" {
  description = "Threshold percentages for budget alerts"
  type        = list(number)
  default     = [80, 100]
}

variable "notification_emails" {
  description = "Email addresses for budget notifications"
  type        = list(string)
  default     = []
  validation {
    condition     = var.enable_cost_controls == false || length(var.notification_emails) > 0
    error_message = "notification_emails must include at least one address when cost controls are enabled."
  }
}

variable "budget_start_date" {
  description = "Budget start date in RFC3339 format (leave empty for current month)"
  type        = string
  default     = ""
}
