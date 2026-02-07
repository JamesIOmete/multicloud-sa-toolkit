variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Metadata to attach to policy assignments"
  type        = map(string)
}

variable "subscription_resource_id" {
  description = "Subscription resource ID for policy assignments"
  type        = string
}

variable "allowed_locations" {
  description = "Azure regions allowed by the guardrail policy"
  type        = list(string)
}
