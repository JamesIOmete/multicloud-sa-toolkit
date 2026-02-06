output "tenant_id" {
  value       = local.tenant_id
  description = "Tenant (directory) ID."
}

output "subscription_id" {
  value       = local.subscription_id
  description = "Subscription ID."
}

output "client_id" {
  value       = azuread_application.github.client_id
  description = "Application (client) ID to use as AZURE_CLIENT_ID in GitHub Actions."
}

output "service_principal_object_id" {
  value       = azuread_service_principal.github.object_id
  description = "Service principal object ID."
}

output "allowed_subjects" {
  value       = local.subjects
  description = "The GitHub OIDC subject claim values allowed."
}

output "github_actions_vars" {
  value = {
    AZURE_CLIENT_ID       = azuread_application.github.client_id
    AZURE_TENANT_ID       = local.tenant_id
    AZURE_SUBSCRIPTION_ID = local.subscription_id
  }
  description = "Set these as GitHub Actions variables (not secrets) for azure/login."
}

output "rbac_scope" {
  value       = local.effective_scope
  description = "Scope used for RBAC assignments (if enabled)."
}

output "rbac_roles" {
  value       = local.effective_roles
  description = "RBAC roles assigned (if enabled)."
}
