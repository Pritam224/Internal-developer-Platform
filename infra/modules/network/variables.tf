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

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the virtual network"
  default     = []
}

variable "owner_email" {
  type        = string
  description = "ThoughtWorks email address of the owner"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging"
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
