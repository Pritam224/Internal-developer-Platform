variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
}

variable "keyvault_name" {
  type        = string
  description = "Name of the aks cluster"
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

variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection (IRREVERSIBLE once true — vault cannot be permanently deleted until retention expires)"
  default     = false
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Days deleted vault/secrets are recoverable (7-90)"
  default     = 7
}

