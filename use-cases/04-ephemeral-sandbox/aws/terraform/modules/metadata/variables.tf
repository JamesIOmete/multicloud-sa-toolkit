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

variable "metadata_table_name" {
  type        = string
  description = "Existing DynamoDB table name to store sandbox metadata"
  default     = ""
}

variable "create_metadata_table" {
  type        = bool
  description = "Create metadata table when true"
  default     = true
}

variable "ttl_hours" {
  type        = number
  description = "Sandbox time-to-live in hours"
  default     = 72
}
