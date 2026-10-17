# Infrastructure Azure (Terraform)

Ressources Azure de l'assistant de bord, décrites en code :

| Ressource | Rôle |
|---|---|
| `rg-ride-with-yan` | Groupe de ressources (tout est rangé ici, effaçable d'un coup) |
| `ai-ride-with-yan` | Ressource Azure AI Foundry (services d'IA), région Canada Est |
| `assistant` | Déploiement du modèle de langage, débit plafonné |

## Utilisation

```bash
az login                      # connexion à Azure
cd infra/azure
terraform init                # télécharge le fournisseur Azure
terraform plan  -var-file=ride.tfvars   # ce qui va changer
terraform apply -var-file=ride.tfvars   # le faire
terraform output -raw api_key           # clé, à mettre dans les secrets Supabase
```

`ride.tfvars` (non versionné) :

```hcl
subscription_id = "…"
model_name      = "…"
model_version   = "…"
```

L'état de Terraform (`terraform.tfstate`) contient la clé du service : il reste
sur le poste, jamais dans Git. Tout supprimer : `terraform destroy`.
