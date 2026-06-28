variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "nsg_name" {
  type        = string
  description = "Name of the network security group"
}

variable "aks_subnet_name" {
  type        = string
  description = "Name of the AKS subnet"
}

variable "database_subnet_name" {
  type        = string
  description = "Name of the database subnet"
}

variable "database_subnet_range" {
  type        = list(string)
  description = "Address prefixes for the database subnet"
}

variable "aks_subnet_range" {
  type        = list(string)
  description = "Address prefixes for the AKS subnet"
}

variable "owner_email" {
  type        = string
  description = "ThoughtWorks email address of the owner"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "keyvault_name" {
  type        = string
  description = "Name of the azure keyvault"
}

variable "acr_name" {
  type        = string
  description = "Provide container registry name"
}

variable "identity_type" {
  type = string
}

variable "acr_sku" {
  type        = string
  description = "SKU tier for the Azure Container Registry (Basic, Standard, Premium)"
}

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the AKS system (default) node pool"
}

variable "aks_sku_tier" {
  type        = string
  description = "AKS control-plane tier (Free, Standard, Premium)"
}