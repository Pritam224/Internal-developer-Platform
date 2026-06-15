terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Auth: OIDC in CI (via the env vars ARM_CLIENT_ID / ARM_TENANT_ID /
# ARM_SUBSCRIPTION_ID + ARM_USE_OIDC=true). Azure CLI when run locally.
provider "azurerm" {
  use_oidc                        = true
  resource_provider_registrations = "none"
  features {}
}
