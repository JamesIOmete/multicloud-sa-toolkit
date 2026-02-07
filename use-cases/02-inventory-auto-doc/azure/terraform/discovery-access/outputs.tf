output "role_assignment_ids" {
  description = "Role assignment IDs created for discovery access"
  value = compact([
    azurerm_role_assignment.reader.id,
    try(azurerm_role_assignment.resource_graph[0].id, "")
  ])
}
