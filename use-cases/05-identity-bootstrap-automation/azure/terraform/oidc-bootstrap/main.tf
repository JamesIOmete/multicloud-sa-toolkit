provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}

provider "azuread" {}

data "azurerm_client_config" "current" {}

locals {
  repo_full = "${var.github_org}/${var.github_repo}"

  # Sensible defaults if you don't specify subject_claim_patterns:
  default_subjects = [
    "repo:${local.repo_full}:ref:refs/heads/main",
    "repo:${local.repo_full}:pull_request",
  ]
  subjects = length(var.subject_claim_patterns) > 0 ? var.subject_claim_patterns : local.default_subjects

  tenant_id       = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  subscription_id = var.subscription_id != "" ? var.subscription_id : data.azurerm_client_config.current.subscription_id

  app_display_name = var.application_display_name != "" ? var.application_display_name : "${var.name_prefix}-${var.env}-github-oidc"

  # Each subject becomes one FIC; Azure does not support wildcard subjects.
  subject_map = {
    for s in local.subjects :
    substr(sha1(s), 0, 12) => s
  }

  effective_scope = var.rbac_scope != "" ? var.rbac_scope : "/subscriptions/${local.subscription_id}"

  # If enable_rbac=true and you didn't specify roles, default to Contributor (demo-friendly).
  effective_roles = var.enable_rbac ? (length(var.role_definition_names) > 0 ? var.role_definition_names : ["Contributor"]) : []
}

resource "azuread_application" "github" {
  display_name = local.app_display_name
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
}

resource "azuread_application_federated_identity_credential" "github" {
  for_each       = local.subject_map
  application_id = azuread_application.github.id

  display_name = substr("gh_${each.key}", 0, 120)
  description  = "GitHub OIDC: ${each.value}"
  issuer       = "https://token.actions.githubusercontent.com"
  subject      = each.value
  audiences    = var.oidc_audiences
}

resource "azurerm_role_assignment" "sp_roles" {
  for_each = toset(local.effective_roles)

  scope                = local.effective_scope
  role_definition_name = each.value
  principal_id         = azuread_service_principal.github.object_id

  # Helps avoid eventual-consistency issues right after SP creation
  skip_service_principal_aad_check = true
}
