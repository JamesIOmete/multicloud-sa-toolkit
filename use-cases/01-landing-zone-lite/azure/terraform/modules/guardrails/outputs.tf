output "policy_assignment_ids" {
  description = "Policy assignment IDs applied by this module"
  value = [
    azurerm_subscription_policy_assignment.allowed_locations.id,
    azurerm_subscription_policy_assignment.deny_public_ip.id
  ]
}
