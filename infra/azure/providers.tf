terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Connexion : celle d'Azure CLI (`az login`). Aucun secret dans ces fichiers.
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
