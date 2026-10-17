output "endpoint" {
  description = "Adresse du service, à donner à la fonction Supabase."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "deployment" {
  description = "Nom du déploiement du modèle."
  value       = azurerm_cognitive_deployment.assistant.name
}

output "api_key" {
  description = "Clé du service (secrète) : terraform output -raw api_key"
  value       = azurerm_cognitive_account.foundry.primary_access_key
  sensitive   = true
}
