output "aks_subnet_id" {
  value       = one([for s in azurerm_virtual_network.vnet.subnet : s.id if s.name == var.aks_subnet_name])
  description = "Resource ID of the AKS subnet"
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}
