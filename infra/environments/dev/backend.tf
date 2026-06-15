# Remote state in Azure Storage. Values are injected by the pipeline via
# `terraform init -backend-config=...` so the same code works locally and in CI.
terraform {
  backend "azurerm" {
    key                  = "dev.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}
