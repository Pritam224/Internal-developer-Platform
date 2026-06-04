resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled

  tags = {
    owners      = var.owner_email
    project     = var.project_name
    environment = var.environment
  }
}

# Private endpoint: places a NIC inside the given subnet with a private IP
# that maps to ACR. Pulls/pushes from inside the VNet hit ACR over this NIC
# instead of the public internet. Only created when enable_private_endpoint = true.
resource "azurerm_private_endpoint" "acr" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.acr_name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}
