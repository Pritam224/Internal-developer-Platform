resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    owners  = var.owner_email
    project = var.project_name
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  subnet {
    name             = var.aks_subnet_name
    address_prefixes = var.aks_subnet_range
  }

  subnet {
    name             = var.database_subnet_name
    address_prefixes = var.database_subnet_range
    security_group   = azurerm_network_security_group.nsg.id
  }

  tags = {
    environment = var.environment
  }
}
