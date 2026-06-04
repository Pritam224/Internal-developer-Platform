terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  subscription_id                 = "e1811a95-7c51-4955-a86e-de0ce0c2cf73"
  resource_provider_registrations = "none"
  features {}
}
