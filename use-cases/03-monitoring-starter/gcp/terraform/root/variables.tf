variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy the resources to."
}

variable "region" {
  type        = string
  description = "The GCP region for the resources."
  default     = "us-central1"
}

variable "name_prefix" {
  type        = string
  description = "The prefix for the resource names."
  default     = "mcsa-uc03"
}

variable "env" {
  type        = string
  description = "The environment name."
  default     = "toolkit-test"
}

variable "owner" {
  type        = string
  description = "The owner of the resources."
  default     = "platform-team"
}

variable "notification_sms_number" {
  type        = string
  description = "The phone number for SMS notifications (E.164 format)."
}
