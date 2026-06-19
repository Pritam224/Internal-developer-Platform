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

variable "owner_email" {
  type        = string
  description = "ThoughtWorks email address of the owner"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging"
}

variable "acr_name" {
  type        = string
  description = "Provide container registry name"
}

variable "sku" {
  type        = string
  description = "Provide sku for ACR"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow public internet access to ACR (set false in prod when using private endpoint)"
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Create a private endpoint for ACR (requires Premium SKU)"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID where the ACR private endpoint NIC is placed"
  default     = null
}


