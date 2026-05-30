variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group"
}

variable "aks_cluster_name" {
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

variable "aks_subnet_id" {
  type        = string
  description = "Resource ID of the AKS subnet"
}


