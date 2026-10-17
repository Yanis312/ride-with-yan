variable "subscription_id" {
  description = "Abonnement Azure (az account show --query id)."
  type        = string
}

variable "location" {
  description = "Région Azure. Canada Est : les questions des passagers restent au Canada."
  type        = string
  default     = "canadaeast"
}

variable "name" {
  description = "Préfixe des ressources."
  type        = string
  default     = "ride-with-yan"
}

variable "model_name" {
  description = "Modèle de langage (petit et peu coûteux suffit pour un assistant de bord)."
  type        = string
}

variable "model_version" {
  description = "Version du modèle (az cognitiveservices model list --location canadaeast)."
  type        = string
}

variable "deployment_sku" {
  description = "« Standard » : traitement dans la région choisie (données au Canada)."
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "Débit maximal, en milliers de jetons par minute. Plafonne aussi la dépense."
  type        = number
  default     = 10
}
