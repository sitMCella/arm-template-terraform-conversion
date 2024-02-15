provider "azurerm" {
  tenant_id       = var.azure_tenant_id
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id       = var.azure_principal_account_client_id
  client_secret   = var.azure_principal_account_client_secret
  features {}
}

terraform {
  required_version = ">= 0.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.91.0"
    }
  }
}
