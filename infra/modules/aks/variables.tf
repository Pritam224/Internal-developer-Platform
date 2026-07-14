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

variable "min_node_count" {
  type        = number
  description = "Minimum node count for autoscaling app node pool (prod only)"
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum node count for autoscaling app node pool (prod only)"
  default     = 3
}

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the AKS system (default) node pool — runs cluster system pods (CoreDNS, kube-proxy, etc.)"
  default     = "Standard_DS2_v2"
}

variable "app_node_vm_size" {
  type        = string
  description = "VM size for the AKS app/workload node pool (created in non-dev environments)"
  default     = "Standard_DS2_v2"
}

variable "aks_sku_tier" {
  type        = string
  description = "AKS control-plane tier (Free, Standard, Premium)"
  default     = "Free"
}

variable "service_cidr" {
  type        = string
  description = "Kubernetes service CIDR (must NOT overlap with VNet address space)"
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "DNS service IP (must be inside service_cidr)"
  default     = "10.1.0.10"
}

variable "pod_cidr" {
  type        = string
  description = "Virtual CIDR for pod IPs in Azure CNI Overlay mode (must NOT overlap the VNet or service_cidr)"
  default     = "192.168.0.0/16"
}

variable "acr_name" {
  type        = string
  description = "Name of the ACR to grant AcrPull on (kubelet identity gets AcrPull)"
}


