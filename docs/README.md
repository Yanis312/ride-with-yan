# Comprendre Ride with Yan

Cette documentation explique **comment l'application est construite**, du
bouton sur l'écran jusqu'au serveur d'IA à Montréal. Elle suit la méthode des
grands projets open source : une vue d'ensemble d'abord (le *contexte*), puis
on zoome sur chaque partie (inspiré du [modèle C4](https://c4model.com) et du
modèle `ARCHITECTURE.md` recommandé pour les dépôts).

Les schémas sont écrits en [Mermaid](https://mermaid.js.org) : GitHub les
dessine directement dans la page.

## Ordre de lecture

| # | Fichier | Ce que tu y apprends |
|---|---|---|
| 1 | [Architecture](01-architecture.md) | Les pièces du système, l'arborescence du dépôt, le trajet d'une course |
| 2 | [L'app Flutter](02-flutter.md) | Écrans, état, navigation, interface, appels réseau (l'équivalent de `fetch`/Axios) |
| 3 | [La base Supabase](03-base-de-donnees.md) | Tables, règles de sécurité (RLS), fonctions SQL, fonctions serveur |
| 4 | [Les tests](04-tests.md) | Les quatre niveaux de tests, avec des exemples du dépôt |
| 5 | [CI/CD](05-ci-cd.md) | Ce qui se passe à chaque push et chaque nuit |
| 6 | [Terraform](06-terraform.md) | L'infrastructure Azure en code, commande par commande |
| 7 | [Azure AI Foundry](07-azure-ai.md) | Yan, la voix, les labs, et l'équivalent dans le portail Azure |

## En une phrase par partie

- **`app/`** : l'application Flutter (tablette Android et site web).
- **`supabase/`** : la base de données PostgreSQL et les petites fonctions serveur.
- **`infra/azure/`** : les services d'IA d'Azure, décrits en Terraform.
- **`e2e/`** : les tests qui pilotent un vrai navigateur et l'API.
- **`.github/workflows/`** : les robots qui testent et publient à chaque changement.
- **`labs/`** : les scripts Python pour réviser les certifications Azure.
