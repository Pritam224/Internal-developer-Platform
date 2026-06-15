resource_group_name   = "rg-app-dev"
location              = "eastus"
environment           = "dev"
vnet_name             = "vnet-dev"
address_space         = ["10.0.0.0/24"]
nsg_name              = "nsg-dev"
aks_subnet_name       = "app-subnet-dev"
database_subnet_name  = "database-subnet-dev"
database_subnet_range = ["10.0.0.0/26"]
aks_subnet_range      = ["10.0.0.64/26"]
owner_email           = "pritam.singh@thoughtworks.com"
project_name          = "internal-developer-platform"
aks_cluster_name      = "aks-idp-dev"
keyvault_name         = "keyvault-idp-dev"
acr_name              = "acrIdpDev"
identity_type         = "UserAssigned"
sku                   = "Basic"



