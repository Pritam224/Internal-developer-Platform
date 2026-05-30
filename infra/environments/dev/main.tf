module "network" {
  source                = "../../modules/network"
  resource_group_name   = var.resource_group_name
  location              = var.location
  environment           = var.environment
  vnet_name             = var.vnet_name
  nsg_name              = var.nsg_name
  address_space         = var.address_space
  aks_subnet_name       = var.aks_subnet_name
  aks_subnet_range      = var.aks_subnet_range
  database_subnet_name  = var.database_subnet_name
  database_subnet_range = var.database_subnet_range
  owner_email           = var.owner_email
  project_name          = var.project_name
}

module "aks" {
  source = "../../modules/aks"

  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  aks_cluster_name    = var.aks_cluster_name
  aks_subnet_id       = module.network.aks_subnet_id
  owner_email         = var.owner_email
  project_name        = var.project_name
}

module "keyvault" {
  source = "../../modules/keyvault"

  keyvault_name       = var.keyvault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  owner_email         = var.owner_email
  project_name        = var.project_name
}
