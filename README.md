<p align="center"><img src="branding/logo-preview.png" width="480" alt="Ride with Yan"></p>

# Ride with Yan

[![Tests](https://github.com/Yanis312/ride-with-yan/actions/workflows/tests.yml/badge.svg)](https://github.com/Yanis312/ride-with-yan/actions/workflows/tests.yml)
[![Nightly](https://github.com/Yanis312/ride-with-yan/actions/workflows/nightly.yml/badge.svg)](https://github.com/Yanis312/ride-with-yan/actions/workflows/nightly.yml)
[![Web preview](https://github.com/Yanis312/ride-with-yan/actions/workflows/web-preview.yml/badge.svg)](https://github.com/Yanis312/ride-with-yan/actions/workflows/web-preview.yml)

Application bilingue (anglais / français) pour une tablette fixée derrière le siège d'un chauffeur. Elle divertit les passagers pendant la course et leur présente une boutique, des services de création de sites et d'applications, et des espaces publicitaires.

**Essayer l'app :** https://yanis312.github.io/ride-with-yan/

## Comprendre le projet

La documentation détaillée, avec des schémas, est dans [`docs/`](docs/README.md) :
architecture, app Flutter, base Supabase, tests, CI/CD, Terraform et Azure AI.

## Ce que fait l'app

- **Écran de veille** qui fait défiler dix présentations et invite à toucher l'écran.
- **Lounge** : vidéos, musique, nouvelles, météo, question du jour.
- **Boutique** : catalogue, panier, coordonnées du client, paiement par virement Interac, articles sur commande livrés à domicile.
- **Panneau d'administration** (`?admin`) : commandes reçues, prix, stock, sondage.
- **Alerte sur téléphone** à chaque nouvelle commande.

## Technologies

| Partie | Outils |
|---|---|
| Application | Flutter (Android et Web en WebAssembly), Dart |
| Données | Supabase (PostgreSQL, règles de sécurité par ligne, fonctions SQL) |
| Tests de l'app | `flutter test` (tests unitaires et de widgets) |
| Tests de bout en bout et d'API | Playwright, TypeScript, Zod, ESLint, axe-core (accessibilité) |
| IA pour les tests | Agents Playwright (planner, generator, healer) avec Claude Code |
| Conteneurs | Docker, Docker Compose |
| Intégration continue | GitHub Actions, Azure Pipelines |
| Déploiement | GitHub Pages (web), GitHub Releases (APK Android) |

## Structure du dépôt

| Dossier | Contenu |
|---|---|
| `app/` | Application Flutter |
| `e2e/` | Tests Playwright : écrans (`tests/ui`) et API (`tests/api`) |
| `supabase/` | Schéma de la base et règles de sécurité |
| `.github/workflows/` | Pipelines GitHub Actions |
| `azure-pipelines.yml` | Pipeline Azure DevOps |
| `video/` | Vidéos de présentation (Remotion) |
| `tools/` | Scripts de préparation des photos de produits |

## Tests

Trois niveaux, du plus rapide au plus proche du passager :

1. **Tests unitaires et de widgets** (`app/test`) : panier, stock, session, panneau d'administration, mise en page à la taille d'une tablette.
2. **Tests d'API** (`e2e/tests/api`) : ils jouent le rôle d'un inconnu qui n'a que la clé publique de l'app et vérifient que la base refuse tout ce qu'elle doit refuser : lire les commandes des clients, changer un prix, déposer une commande déjà « payée », envoyer des données invalides. Les réponses sont validées par des schémas Zod.
3. **Tests de bout en bout** (`e2e/tests/ui`) : un vrai navigateur ouvre l'app et suit le parcours d'un passager, de l'écran de veille jusqu'au paiement Interac, y compris quand le réseau tombe au moment de commander.

4. **Tests d'accessibilité** (`e2e/tests/ui/accessibility.spec.ts`) : axe-core vérifie les règles WCAG 2 (A et AA) sur l'écran de veille, le lounge, la boutique et le formulaire. Ils ont trouvé, puis fait corriger, des boutons sans nom et des images sans description.

Les tests d'écran suivent le modèle *Page Object* (`e2e/src/pages`). Les appels à la base y sont interceptés (`e2e/src/fixtures.ts`) : ils n'écrivent jamais dans la vraie base et donnent le même résultat à chaque exécution.

### Lancer les tests

```bash
# Tests de l'app
cd app
flutter pub get
flutter test

# Tests Playwright (l'app web doit être construite d'abord)
flutter build web --release --wasm
cd ../e2e
npm ci
npx playwright install chromium
npx playwright test                 # écrans + API
npx playwright test --project=api   # API seulement
npx playwright show-report          # rapport détaillé
```

Dans Docker, sans rien installer d'autre : `docker compose run --rm e2e` (après le build web).

Agents IA : `e2e/specs/README.md` explique comment demander à Claude Code de planifier, écrire ou réparer des tests.

Variables utiles : `ALL_BROWSERS=1` ajoute Firefox et WebKit (le moteur de Safari), `APP_URL=…` teste une app déjà en ligne, `PW_CHANNEL=chrome` réutilise le Chrome installé sur le poste.

## Intégration continue

| Pipeline | Quand | Ce qu'il fait |
|---|---|---|
| **Tests** (GitHub Actions) | À chaque envoi de code et à chaque demande de fusion | Mise en forme, analyse statique, tests Flutter, construction de l'app web, puis types, lint et tests Playwright sur Chromium. Le rapport est joint à l'exécution. |
| **Nightly** (GitHub Actions) | Chaque nuit | Toute la suite sur Chromium, Firefox et WebKit, répartie sur trois machines en parallèle, rapports fusionnés en un seul. Un contrôle passe aussi sur le site réellement en ligne. |
| **Azure Pipelines** | Chaque nuit | La même chaîne sur Azure DevOps ; les résultats sont publiés au format JUnit dans l'onglet « Tests ». |
| **Web preview** (GitHub Actions) | À chaque envoi sur `main` | Publie l'app web sur GitHub Pages. |
| **Docker** (GitHub Actions) | Quand les tests ou les fichiers Docker changent | La suite tourne dans des conteneurs (`docker compose`). |
| **Dependabot** | Chaque semaine | Ouvre une pull request pour chaque mise à jour de dépendance (npm, pub, actions). |
| **Android APK** (GitHub Actions) | À chaque envoi sur `main` | Construit l'APK et le publie dans les *Releases*. |

## Lancer l'app

```bash
cd app
flutter pub get
flutter run -d chrome
```
