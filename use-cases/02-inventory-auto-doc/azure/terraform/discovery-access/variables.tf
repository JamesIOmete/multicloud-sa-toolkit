variable "principal_object_id" {
  description = "Service principal object ID for the GitHub OIDC application"
  type        = string
}

variable "enable_resource_graph_role" {
  description = "Assign Resource Graph Reader role to the principal"
  type        = bool
  default     = true
}
