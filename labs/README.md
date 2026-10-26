# Labs Azure AI : une semaine pour l'examen AI-901

Un service par lab, toujours le même déroulé (**30 à 45 minutes**) :

1. **Portail (10 min)** : voir la ressource et l'essayer en cliquant.
2. **Lire le script (10 min)** : le haut du fichier liste ce que l'examen
   demande de reconnaître.
3. **Lancer et changer une chose (15 min)** : ton texte, ta photo, ta facture.
4. **Noter le piège (5 min)** : la ligne « Piège » du tableau plus bas.

## Préparer (une seule fois)

```powershell
cd D:\Yan\ride-with-yan\labs
.venv\Scripts\python -m pip install -r requirements.txt
.venv\Scripts\python cles.py --depuis-terraform     # remplit .env, n'affiche aucune clé
```

Dans VS Code : **Ctrl+Shift+P** → *Python: Select Interpreter* →
`labs\.venv`. Les soulignements « not installed » disparaissent.

## Le plan de la semaine

| Jour | Lab | Commande | Ce que tu dois voir |
|---|---|---|---|
| 1 | Translator | `.venv\Scripts\python 02-translator\traduire.py` | Langue détectée, 3 traductions, une translittération |
| 1 | Language | `.venv\Scripts\python 03-language\avis.py` | Sentiment, phrases clés, entités, numéro de téléphone masqué |
| 2 | Vision | `.venv\Scripts\python 04-vision\lire.py` | Texte lu sur la photo, mots-clés, objets avec leur cadre |
| 2 | Document Intelligence | `.venv\Scripts\python 05-documents\facture.py` | Fournisseur, total, date, avec un % de confiance |
| 3 | AI Search + RAG | `.venv\Scripts\python 06-rag\chercher.py` | Les sources trouvées, puis la réponse de Yan (« je ne sais pas » pour les casquettes) |
| 4 | Content Safety | `.venv\Scripts\python 07-safety\moderer.py` | Une sévérité 0 à 6 par catégorie, et la décision |
| 4 | Speech (révision) | `.venv\Scripts\python 01-speech\parler.py "Bonjour"` | `reponse.wav` |
| 5 | Foundry | Portail seulement (voir plus bas) | Modèles, déploiements, terrain de jeu, filtres de contenu |
| 6–7 | Révision | Évaluation d'entraînement gratuite de Microsoft Learn (page de l'examen AI-901) | Refaire les labs des thèmes ratés |

## Côté portail, pour chaque lab

Microsoft déplace peu à peu les anciens « Studios » dans **Foundry**
(https://ai.azure.com). Si un lien te redirige, suis la redirection.

| Lab | Où cliquer |
|---|---|
| Tous | Portail Azure → `rg-ride-with-yan` → la ressource → **Vue d'ensemble** (adresse, région, niveau F0) puis **Clés et point de terminaison** (2 clés : on en change une pendant que l'autre sert) |
| Translator, Language | Foundry → ressource `ai-ride-with-yan` → **Terrains de jeu** → Language / Translator : colle un avis, essaie sentiment et PII |
| Vision | Foundry → **Terrains de jeu** → Vision : dépose une photo de carte de commerce |
| Document Intelligence | https://documentintelligence.ai.azure.com → modèle **Facture** → ressource `documents-ride-with-yan` → dépose une facture |
| AI Search | Portail Azure → `search-ride-with-yan` → **Index** → `yan-connaissances` (créé par le lab) → **Explorateur de recherche** : tape `livraison` |
| Content Safety | Foundry → **Content Safety** (ou Content Safety Studio) → *Modérer le contenu textuel* : regarde les curseurs de seuil |
| Foundry (jour 5) | Foundry → `ai-ride-with-yan` → **Modèles + points de terminaison** (le déploiement `assistant`), **Terrain de jeu de conversation**, **Garde-fous / filtres de contenu** |

> Les essais dans Foundry utilisent `ai-ride-with-yan` (niveau payant S0) :
> quelques fractions de cent. Le budget de 10 $ CA te prévient bien avant.

## Les pièges classiques de l'examen

| Service | Piège |
|---|---|
| Speech, Translator | Le client veut la **région** (`canadacentral`) en plus de la clé. Les autres services veulent l'**adresse** |
| Translator | Sans `from_language`, la langue est **détectée**. *Translittérer* = changer d'alphabet, pas de langue |
| Language | Un résultat **par document** : vérifier `is_error`. Sentiment possible : positive, neutral, negative, **mixed** |
| Language | **NER** (entités : lieux, personnes) ≠ **PII** (données personnelles à masquer) |
| Vision | **OCR** (`READ`) lit le texte ; **Document Intelligence** comprend la structure (quel nombre est le total) |
| Vision | `CAPTION` n'existe que dans certaines régions (pas Canada Centre) |
| Document Intelligence | `begin_…` = opération **longue** : on attend avec `.result()`. Modèles **prêts** (facture, reçu, pièce d'identité) ou **personnalisés** |
| AI Search | **Index** = le schéma ; **indexeur** = le robot qui le remplit depuis une source. Recherche par mots-clés, vectorielle, hybride, sémantique |
| RAG | Le modèle répond **à partir des sources trouvées**, ce qui limite les inventions (*hallucinations*). `model=` reçoit le nom du **déploiement** |
| Content Safety | 4 catégories (haine, automutilation, sexuel, violence), sévérité **0, 2, 4, 6**. C'est **toi** qui fixes le seuil |
| IA responsable | 6 principes : équité, fiabilité et sécurité, confidentialité et sécurité, inclusion, transparence, responsabilité |

## Après l'examen

On branche ces services dans l'app, un par un : traduire les offres des
annonceurs, analyser les avis, lire la carte d'un commerce, et laisser Yan
répondre à partir d'une base de connaissances.
