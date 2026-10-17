locals {
  tags = {
    projet   = "ride-with-yan"
    gere-par = "terraform"
  }
}

resource "azurerm_resource_group" "ride" {
  name     = "rg-${var.name}"
  location = var.location
  tags     = local.tags
}

# Ressource Azure AI Foundry (services d'IA) qui héberge le modèle.
resource "azurerm_cognitive_account" "foundry" {
  name                  = "ai-${var.name}"
  location              = azurerm_resource_group.ride.location
  resource_group_name   = azurerm_resource_group.ride.name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = "ai-${var.name}"
  tags                  = local.tags
}

# Le modèle de l'assistant, déployé dans cette ressource.
resource "azurerm_cognitive_deployment" "assistant" {
  name                 = "assistant"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = var.model_name
    version = var.model_version
  }

  sku {
    name     = var.deployment_sku
    capacity = var.capacity
  }
}
