resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  base_name = replace(replace(lower(var.name_prefix), "-", ""), "_", "")
  dns_label = substr("${local.base_name}${random_string.suffix.result}", 0, 50)
  group_name = substr(replace(replace(lower(var.name_prefix), "_", "-"), " ", "-"), 0, 60)
}

resource "azurerm_container_group" "sandbox" {
  name                = local.group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = local.dns_label
  os_type             = "Linux"
  tags                = var.tags

  container {
    name   = "app"
    image  = var.container_image
    cpu    = var.cpu
    memory = var.memory

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
