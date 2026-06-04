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
  source     = "../../modules/aks"
  depends_on = [module.network]

  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  aks_cluster_name    = var.aks_cluster_name
  aks_subnet_id       = module.network.aks_subnet_id
  owner_email         = var.owner_email
  project_name        = var.project_name
  min_node_count      = var.min_node_count
  max_node_count      = var.max_node_count
  node_vm_size        = var.node_vm_size
  service_cidr        = var.service_cidr
  dns_service_ip      = var.dns_service_ip
}

module "keyvault" {
  source     = "../../modules/keyvault"
  depends_on = [module.network]

  keyvault_name       = var.keyvault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  owner_email         = var.owner_email
  project_name        = var.project_name

  # Prod hardening
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
}

module "acr" {
  source     = "../../modules/acr"
  depends_on = [module.network]

  acr_name            = var.acr_name
  sku                 = var.sku
  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  owner_email         = var.owner_email
  project_name        = var.project_name

  # Prod hardening
  admin_enabled                 = false
  public_network_access_enabled = false
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = module.network.aks_subnet_id
}
