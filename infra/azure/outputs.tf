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

output "lab_endpoints" {
  description = "Adresses des services du laboratoire."
  value       = { for k, v in azurerm_cognitive_account.lab : k => v.endpoint }
}

output "lab_keys" {
  description = "Clés des services du laboratoire (secrètes) : terraform output -json lab_keys"
  value       = { for k, v in azurerm_cognitive_account.lab : k => v.primary_access_key }
  sensitive   = true
}

output "search_endpoint" {
  value = "https://${azurerm_search_service.lab.name}.search.windows.net"
}

output "search_admin_key" {
  value     = azurerm_search_service.lab.primary_key
  sensitive = true
}
