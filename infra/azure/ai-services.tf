# Services d'IA d'Azure pour le laboratoire (certifications AI-901 et AI-103).
# Tous au niveau gratuit (F0) : un seul par type et par abonnement.
#
# | Service              | kind             | Gratuit par mois                     |
# |----------------------|------------------|--------------------------------------|
# | Speech               | SpeechServices   | 0,5 M caractères de voix, 5 h d'écoute |
# | Translator           | TextTranslation  | 2 M caractères                       |
# | Language             | TextAnalytics    | 5 000 textes                         |
# | Vision               | ComputerVision   | 5 000 images                         |
# | Document Intelligence| FormRecognizer   | 500 pages                            |
# | Content Safety       | ContentSafety    | 5 000 textes, 5 000 images           |

locals {
  ai_services = {
    speech     = "SpeechServices"
    translator = "TextTranslation"
    language   = "TextAnalytics"
    vision     = "ComputerVision"
    documents  = "FormRecognizer"
    safety     = "ContentSafety"
  }
}

resource "azurerm_cognitive_account" "lab" {
  for_each = local.ai_services

  name                  = "${each.key}-${var.name}"
  location              = var.lab_location
  resource_group_name   = azurerm_resource_group.ride.name
  kind                  = each.value
  sku_name              = "F0"
  custom_subdomain_name = "${each.key}-${var.name}"
  tags                  = local.tags
}

# Recherche (RAG / Foundry IQ) : niveau gratuit, 50 Mo, 3 index.
resource "azurerm_search_service" "lab" {
  name                = "search-${var.name}"
  location            = var.lab_location
  resource_group_name = azurerm_resource_group.ride.name
  sku                 = "free"
  tags                = local.tags
}
