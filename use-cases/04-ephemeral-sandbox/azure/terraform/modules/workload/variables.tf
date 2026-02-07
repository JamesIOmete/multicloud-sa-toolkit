variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "container_image" {
  description = "Container image for the workload"
  type        = string
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = number
}

variable "memory" {
  description = "Memory (GB) for the container"
  type        = number
}
