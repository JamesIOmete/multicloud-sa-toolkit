variable "github_org" {
  type        = string
  description = "GitHub org or username that owns the repo (e.g., jward448)."
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name (e.g., multicloud-sa-toolkit)."
}

variable "subject_claim_patterns" {
  type        = list(string)
  description = <<EOT
Allowed GitHub OIDC 'sub' claim values.
NOTE (Azure): Each entry becomes a separate federated identity credential; wildcards are not supported.
Examples:
- repo:ORG/REPO:ref:refs/heads/main
- repo:ORG/REPO:pull_request
- repo:ORG/REPO:environment:prod
EOT
  default     = []
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource naming."
  default     = "mcsa-uc05"
}

variable "env" {
  type        = string
  description = "Environment name."
  default     = "toolkit-test"
}

variable "owner" {
  type        = string
  description = "Owner tag value / identifier."
  default     = "platform-team"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID. Leave empty to auto-detect from azurerm_client_config."
  default     = ""
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Leave empty to auto-detect from azurerm_client_config."
  default     = ""
}

variable "oidc_audiences" {
  type        = list(string)
  description = "OIDC audiences for the federated credential (Azure default is api://AzureADTokenExchange)."
  default     = ["api://AzureADTokenExchange"]
}

variable "application_display_name" {
  type        = string
  description = "Optional display name for the Entra application. Leave empty for a generated name."
  default     = ""
}

variable "enable_rbac" {
  type        = bool
  description = "Whether to create Azure RBAC role assignments for the service principal."
  default     = false
}

variable "rbac_scope" {
  type        = string
  description = "RBAC scope for role assignments. Leave empty to default to the subscription scope."
  default     = ""
}

variable "role_definition_names" {
  type        = list(string)
  description = "Role definition names to assign at the chosen scope (e.g., Contributor). Only used if enable_rbac=true."
  default     = []
}
