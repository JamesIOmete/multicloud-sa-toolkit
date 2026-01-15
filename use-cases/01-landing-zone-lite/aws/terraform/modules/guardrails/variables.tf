variable "name_prefix" {
  description = "Base name prefix for guardrail resources"
  type        = string
}

variable "tags" {
  description = "Additional tags applied to guardrail resources"
  type        = map(string)
  default     = {}
}

variable "enable_guardrail_alerts" {
  description = "Enable EventBridge + SNS alerts for guardrail events"
  type        = bool
  default     = true
}

variable "enable_config_guardrails" {
  description = "Enable AWS Config specific guardrail alerts"
  type        = bool
  default     = true
}

variable "notification_emails" {
  description = "List of email addresses subscribed to guardrail alerts"
  type        = list(string)
  default     = []
}

variable "enable_scp_pack" {
  description = "Whether to create and attach the optional SCP guardrail pack"
  type        = bool
  default     = false
}

variable "scp_target_ids" {
  description = "List of AWS Organizations target IDs (accounts/OUs) to attach the SCP"
  type        = list(string)
  default     = []
}
