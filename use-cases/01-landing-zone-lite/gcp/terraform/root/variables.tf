variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy the resources to."
  default     = "mcsa-uc01-dev"
}

variable "region" {
  type        = string
  description = "The GCP region for the resources."
  default     = "us-central1"
}

variable "name_prefix" {
  type        = string
  description = "The prefix for the resource names."
  default     = "mcsa-uc01"
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

variable "budget_amount" {
  type        = number
  description = "The amount for the budget alert, in the currency of the billing account."
  default     = 50
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID or full resource name (000000-000000-000000 or billingAccounts/000000-000000-000000)."
}
